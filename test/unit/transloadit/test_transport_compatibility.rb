require "test_helper"
require "stringio"
require "tempfile"

describe "Faraday transport compatibility" do
  include WebMock::API

  before do
    WebMock.reset!
  end

  after do
    WebMock.reset!
  end

  it "sends signed GET parameters and the client header to a selected host" do
    endpoint = "https://api2.example.test/assemblies/assembly-id"
    stub_request(:get, /\A#{Regexp.escape(endpoint)}/)
      .to_return(status: 200, body: '{"ok":"ASSEMBLY_COMPLETED"}')

    response = Transloadit::Request.new(endpoint, "secret").get(wait: true)

    _(response["ok"]).must_equal "ASSEMBLY_COMPLETED"
    assert_requested(:get, /\A#{Regexp.escape(endpoint)}/) do |request|
      query = Addressable::URI.parse(request.uri.to_s).query_values
      _(MultiJson.load(query.fetch("params"))).must_equal "wait" => true
      _(query.fetch("signature")).must_match(/\Asha384:[0-9a-f]{96}\z/)
      _(request.headers.fetch("Transloadit-Client")).must_equal "ruby-sdk:#{Transloadit::VERSION}"
    end
  end

  it "form-encodes signed POST payloads" do
    endpoint = "https://api2.transloadit.com/assemblies"
    stub_request(:post, endpoint)
      .to_return(status: 200, body: '{"ok":"ASSEMBLY_COMPLETED"}')

    Transloadit::Request.new("/assemblies", "secret").post(params: {template_id: "template-id"})

    assert_requested(:post, endpoint) do |request|
      form = URI.decode_www_form(request.body).to_h
      _(MultiJson.load(form.fetch("params"))).must_equal "template_id" => "template-id"
      _(form.fetch("signature")).must_match(/\Asha384:[0-9a-f]{96}\z/)
      _(request.headers.fetch("Content-Type")).must_match(/\Aapplication\/x-www-form-urlencoded/)
    end
  end

  it "form-encodes signed PUT payloads" do
    endpoint = "https://api2.transloadit.com/templates/template-id"
    stub_request(:put, endpoint)
      .to_return(status: 200, body: '{"ok":"TEMPLATE_UPDATED"}')

    Transloadit::Request.new("/templates/template-id", "secret").put(params: {name: "Updated"})

    assert_requested(:put, endpoint) do |request|
      form = URI.decode_www_form(request.body).to_h
      _(MultiJson.load(form.fetch("params"))).must_equal "name" => "Updated"
      _(form.fetch("signature")).must_match(/\Asha384:[0-9a-f]{96}\z/)
    end
  end

  it "form-encodes signed DELETE payloads" do
    endpoint = "https://api2.transloadit.com/templates/template-id"
    stub_request(:delete, endpoint)
      .to_return(status: 200, body: '{"ok":"TEMPLATE_DELETED"}')

    Transloadit::Request.new("/templates/template-id", "secret").delete(params: {reason: "cleanup"})

    assert_requested(:delete, endpoint) do |request|
      form = URI.decode_www_form(request.body).to_h
      _(MultiJson.load(form.fetch("params"))).must_equal "reason" => "cleanup"
      _(form.fetch("signature")).must_match(/\Asha384:[0-9a-f]{96}\z/)
    end
  end

  it "returns non-success responses with SDK-owned status, headers, and body access" do
    endpoint = "https://api2.example.test/assemblies/missing"
    stub_request(:get, endpoint).to_return(
      status: 422,
      headers: {"Retry-After" => "5", "X-Request-Id" => "request-id"},
      body: '{"error":"ASSEMBLY_NOT_FOUND"}'
    )

    response = Transloadit::Request.new(endpoint).get

    _(response).must_be_kind_of Transloadit::Response
    _(response).wont_be_kind_of Faraday::Response
    _(response.code).must_equal 422
    _(response.status).must_equal 422
    _(response.headers).must_equal retry_after: "5", x_request_id: "request-id"
    _(response["error"]).must_equal "ASSEMBLY_NOT_FOUND"
  end

  it "returns redirects without following them" do
    endpoint = "https://api2.example.test/assemblies"
    redirect = "https://uploads.example.test/assemblies"
    stub_request(:post, endpoint).to_return(
      status: 302,
      headers: {"Location" => redirect},
      body: "{}"
    )

    response = Transloadit::Request.new(endpoint).post

    _(response.code).must_equal 302
    _(response.headers[:location]).must_equal redirect
    assert_not_requested(:post, redirect)
  end

  it "uploads multiple files after params and signature without closing caller-owned files" do
    endpoint = "https://api2.transloadit.com/assemblies"
    stub_request(:post, endpoint)
      .to_return(status: 200, body: '{"ok":"ASSEMBLY_COMPLETED"}')

    Tempfile.create(["first", ".txt"]) do |first|
      Tempfile.create(["second", ".json"]) do |second|
        first.write("first upload")
        first.flush
        second.write('{"second":"upload"}')
        second.flush

        Transloadit::Request.new("/assemblies", "secret").post(
          params: {steps: {}},
          file_0: first,
          file_1: second
        )

        _(first.closed?).must_equal false
        _(second.closed?).must_equal false
      end
    end

    assert_requested(:post, endpoint) do |request|
      params_position = request.body.index('name="params"')
      signature_position = request.body.index('name="signature"')
      first_position = request.body.index('name="file_0"')
      second_position = request.body.index('name="file_1"')

      _(request.headers.fetch("Content-Type")).must_match(/\Amultipart\/form-data; boundary=/)
      _(params_position).wont_be_nil
      _(signature_position).wont_be_nil
      _(first_position).wont_be_nil
      _(second_position).wont_be_nil
      _(params_position < signature_position).must_equal true
      _(signature_position < first_position).must_equal true
      _(first_position < second_position).must_equal true
      _(request.body).must_include "Content-Type: text/plain"
      _(request.body).must_include "Content-Type: application/json"
      _(request.body).must_include "first upload"
      _(request.body).must_include '{"second":"upload"}'
    end
  end

  it "preserves filename and content type from Rails-style uploaded files" do
    endpoint = "https://api2.transloadit.com/assemblies"
    stub_request(:post, endpoint)
      .to_return(status: 200, body: '{"ok":"ASSEMBLY_COMPLETED"}')

    Tempfile.create(["rails-upload", ".bin"]) do |file|
      file.write("csv contents")
      file.flush
      upload = Object.new
      upload.define_singleton_method(:read) { |*arguments| file.read(*arguments) }
      upload.define_singleton_method(:path) { file.path }
      upload.define_singleton_method(:original_filename) { "report.csv" }
      upload.define_singleton_method(:content_type) { "text/csv" }

      Transloadit::Request.new("/assemblies").post(params: {steps: {}}, file_0: upload)
    end

    assert_requested(:post, endpoint) do |request|
      _(request.body).must_include 'filename="report.csv"'
      _(request.body).must_include "Content-Type: text/csv"
      _(request.body).must_include "csv contents"
    end
  end

  it "uses safe metadata defaults for in-memory uploads" do
    endpoint = "https://api2.transloadit.com/assemblies"
    stub_request(:post, endpoint)
      .to_return(status: 200, body: '{"ok":"ASSEMBLY_COMPLETED"}')
    upload = StringIO.new("memory upload")

    Transloadit::Request.new("/assemblies").post(params: {steps: {}}, file_0: upload)

    _(upload.closed?).must_equal false
    assert_requested(:post, endpoint) do |request|
      _(request.body).must_include 'filename="upload"'
      _(request.body).must_include "Content-Type: application/octet-stream"
      _(request.body).must_include "memory upload"
    end
  end

  it "uses the binary content type when a file extension is unknown" do
    endpoint = "https://api2.transloadit.com/assemblies"
    stub_request(:post, endpoint)
      .to_return(status: 200, body: '{"ok":"ASSEMBLY_COMPLETED"}')

    Tempfile.create(["upload", ".transloadit-unknown"]) do |upload|
      upload.write("unknown upload")
      upload.flush

      Transloadit::Request.new("/assemblies").post(params: {steps: {}}, file_0: upload)
    end

    assert_requested(:post, endpoint) do |request|
      _(request.body).must_include "Content-Type: application/octet-stream"
      _(request.body).must_include "unknown upload"
    end
  end

  it "wraps adapter failures and retains the original error as the cause" do
    endpoint = "https://api2.example.test/assemblies/assembly-id"
    stub_request(:get, endpoint).to_timeout

    error = assert_raises Transloadit::Exception::RequestFailed do
      Transloadit::Request.new(endpoint).get
    end

    _(error.message).must_equal "Transloadit request failed"
    _(error.cause).must_be_kind_of Faraday::ConnectionFailed
  end
end
