require "test_helper"
require "stringio"
require "tempfile"

describe "Assembly uploads and custom fields" do
  include WebMock::API

  before do
    WebMock.reset!
    @transloadit = Transloadit.new(key: "key", secret: "secret")
    @requests = []
    stub_request(:post, "https://api2.transloadit.com/assemblies").to_return do |request|
      @requests << request
      {body: '{"ok":"ASSEMBLY_COMPLETED"}'}
    end
    @fields = {
      "count" => 2,
      "enabled" => false,
      "ratio" => 1.5,
      "empty" => nil,
      "tags" => ["hello & goodbye", 3, true, nil],
      "details" => {"caption" => "café + 猫", "visible" => true}
    }
  end

  after do
    WebMock.reset!
  end

  it "sends typed custom fields only in signed JSON without uploads" do
    @transloadit.assembly(fields: @fields).create!

    _(body_parts.map(&:first)).must_equal %w[params signature]
    _(signed_params.fetch("fields")).must_equal @fields
  end

  it "sends named File parts separately from typed fields with the same name" do
    Tempfile.create(["assembly-upload", ".bin"]) do |file|
      file.binmode
      file.write("named\x00\xff upload".b)
      file.flush
      fields = @fields.merge("hero" => "metadata for the hero")
      uploads = {hero: file}.freeze
      assembly = @transloadit.assembly(uploads: uploads, fields: fields.freeze)

      _, warning = capture_io { assembly.create! }

      _(warning).wont_include "Passing upload IOs in fields"
      _(body_parts.map(&:first)).must_equal %w[params signature hero]
      _(body_parts.to_h.fetch("hero")).must_equal "named\x00\xff upload".b
      _(signed_params.fetch("fields")).must_equal fields
      _(signed_params).wont_include "uploads"
      _(assembly.to_hash).wont_include :uploads
      _(file.closed?).must_equal false
      _(uploads[:hero]).must_equal file
    end
  end

  it "allows per-call uploads and fields to override constructor defaults" do
    defaults = {unused: StringIO.new("unused upload")}
    assembly = @transloadit.assembly(uploads: defaults, fields: {unused: true})
    upload = StringIO.new("named upload")
    positional = StringIO.new("positional upload")

    assembly.create!(positional, uploads: {"hero" => upload}, fields: @fields)

    _(body_parts.map(&:first)).must_equal %w[params signature hero file_0]
    _(body_parts.to_h.fetch("hero")).must_equal "named upload"
    _(body_parts.to_h.fetch("file_0")).must_equal "positional upload"
    _(signed_params.fetch("fields")).must_equal @fields
    _(signed_params).wont_include "uploads"
    _(upload.closed?).must_equal false
    _(positional.closed?).must_equal false
    _(defaults.keys).must_equal [:unused]
  end

  it "preserves legacy mixed fields while deprecating only their upload entries" do
    upload = StringIO.new("legacy upload")
    fields = @fields.merge("hero" => upload).freeze
    assembly = @transloadit.assembly(fields: fields)

    _, warning = capture_io { assembly.create! }

    _(warning).must_match(/fields.*deprecated.*uploads/)
    _(body_parts.map(&:first)).must_equal %w[params signature hero]
    _(body_parts.to_h.fetch("hero")).must_equal "legacy upload"
    _(signed_params.fetch("fields")).must_equal @fields
    _(assembly.to_hash[:fields]).must_equal @fields
    _(JSON.parse(assembly.to_json).fetch("fields")).must_equal @fields
    _(fields.fetch("hero")).must_equal upload
  end

  it "preserves content's create! fields override for legacy named Files" do
    File.open("lib/transloadit/version.rb", "rb") do |file|
      assembly = @transloadit.assembly(fields: {file: file})

      _, warning = capture_io { assembly.create!(fields: @fields) }

      _(warning).must_include "Passing upload IOs in fields is deprecated"
      _(body_parts.map(&:first)).must_equal %w[params signature file]
      _(body_parts.to_h.fetch("file")).must_equal File.binread(file.path)
      _(signed_params.fetch("fields")).must_equal @fields
      _(file.closed?).must_equal false
    end
  end

  it "separates deprecated uploads in per-call fields from custom fields" do
    fields = @fields.merge("hero" => StringIO.new("per-call legacy upload"))

    _, warning = capture_io { @transloadit.assembly.create!(fields: fields) }

    _(warning).must_include "Passing upload IOs in fields is deprecated"
    _(body_parts.map(&:first)).must_equal %w[params signature hero]
    _(body_parts.to_h.fetch("hero")).must_equal "per-call legacy upload"
    _(signed_params.fetch("fields")).must_equal @fields
  end

  it "keeps positional file_N names and priority over legacy upload names" do
    assembly = @transloadit.assembly(fields: {"file_0" => StringIO.new("legacy")})

    capture_io { assembly.create!(StringIO.new("first"), StringIO.new("second")) }

    _(body_parts.map(&:first)).must_equal %w[params signature file_0 file_1]
    _(body_parts.to_h.fetch("file_0")).must_equal "first"
    _(body_parts.to_h.fetch("file_1")).must_equal "second"
    _(signed_params.fetch("fields")).must_equal({})
  end

  it "lets explicit uploads replace deprecated entries with the same wire name" do
    assembly = @transloadit.assembly(fields: {hero: StringIO.new("legacy")})

    capture_io { assembly.create!(uploads: {"hero" => StringIO.new("explicit")}) }

    _(body_parts.map(&:first)).must_equal %w[params signature hero]
    _(body_parts.to_h.fetch("hero")).must_equal "explicit"
    _(signed_params.fetch("fields")).must_equal({})
  end

  it "supports typed per-call fields and an explicitly empty upload override" do
    assembly = @transloadit.assembly(uploads: {hero: StringIO.new("unused")})

    assembly.create!(uploads: {}, fields: @fields)

    _(body_parts.map(&:first)).must_equal %w[params signature]
    _(signed_params.fetch("fields")).must_equal @fields
    _(signed_params).wont_include "uploads"
  end

  it "preserves deprecated fields uploads when only the uploads option is cleared" do
    assembly = @transloadit.assembly(
      uploads: {unused: StringIO.new("unused")},
      fields: {hero: StringIO.new("legacy upload")}
    )

    capture_io { assembly.create!(uploads: {}) }

    _(body_parts.map(&:first)).must_equal %w[params signature hero]
    _(body_parts.to_h.fetch("hero")).must_equal "legacy upload"
    _(signed_params.fetch("fields")).must_equal({})
  end

  it "rejects non-IO named uploads before making a request" do
    error = assert_raises ArgumentError do
      @transloadit.assembly(uploads: {hero: "path/to/file.jpg"}).create!
    end

    _(error.message).must_include "IO"
    _(@requests).must_be_empty
  end

  it "rejects upload names reserved for params and signature" do
    [:params, "signature"].each do |name|
      error = assert_raises ArgumentError do
        @transloadit.assembly.create!(uploads: {name => StringIO.new("upload")})
      end

      _(error.message).must_include "reserved"
    end
    _(@requests).must_be_empty
  end

  it "keeps reserved names safe when they are custom fields" do
    fields = {"params" => {"count" => 2}, "signature" => false}

    @transloadit.assembly(fields: fields).create!

    _(body_parts.map(&:first)).must_equal %w[params signature]
    _(signed_params.fetch("fields")).must_equal fields
  end

  it "retries named uploads with the same bytes and signed custom fields" do
    rate_limit_first_request
    upload = StringIO.new("retry upload")

    capture_io do
      response = @transloadit.assembly(uploads: {hero: upload}, fields: @fields).create!
      _(response.completed?).must_equal true
    end

    _(@requests.length).must_equal 2
    @requests.each do |request|
      _(body_parts(request).map(&:first)).must_equal %w[params signature hero]
      _(body_parts(request).to_h.fetch("hero")).must_equal "retry upload"
      _(signed_params(request).fetch("fields")).must_equal @fields
    end
    _(upload.closed?).must_equal false
  end

  it "retries in-memory uploads from their original position" do
    rate_limit_first_request
    upload = StringIO.new("header:retry upload")
    upload.pos = "header:".length

    capture_io { @transloadit.assembly(uploads: {hero: upload}, fields: @fields).create! }

    _(@requests.length).must_equal 2
    @requests.each do |request|
      _(body_parts(request).to_h.fetch("hero")).must_equal "retry upload"
      _(signed_params(request).fetch("fields")).must_equal @fields
    end
  end

  it "fails clearly instead of retrying a consumed non-seekable upload" do
    rate_limit_first_request
    upload = StringIO.new("streamed upload")
    [:pos, :seek, :rewind].each do |method|
      upload.define_singleton_method(method) { |*| raise Errno::ESPIPE }
    end

    error = assert_raises IOError do
      capture_io { @transloadit.assembly(uploads: {hero: upload}).create! }
    end

    _(error.message).must_include "Cannot retry"
    _(@requests.length).must_equal 1
    _(body_parts.to_h.fetch("hero")).must_equal "streamed upload"
    _(upload.closed?).must_equal false
  end

  def rate_limit_first_request
    stub_request(:post, "https://api2.transloadit.com/assemblies").to_return do |request|
      @requests << request
      body = if @requests.length == 1
        '{"error":"RATE_LIMIT_REACHED","info":{"retryIn":0}}'
      else
        '{"ok":"ASSEMBLY_COMPLETED"}'
      end
      {body: body}
    end
  end

  def body_parts(request = @requests.last)
    content_type = request.headers.fetch("Content-Type")
    return URI.decode_www_form(request.body) unless content_type.start_with?("multipart/form-data")

    boundary = content_type.split("boundary=", 2).last
    request.body.b.split("--#{boundary}".b).filter_map do |part|
      headers, value = part.split("\r\n\r\n", 2)
      next unless value

      [headers[/name="([^"]+)"/, 1], value.delete_suffix("\r\n")]
    end
  end

  def signed_params(request = @requests.last)
    parts = body_parts(request).to_h
    json = parts.fetch("params")
    signature = OpenSSL::HMAC.hexdigest("sha384", "secret", json)
    _(parts.fetch("signature")).must_equal "sha384:#{signature}"
    JSON.parse(json)
  end
end
