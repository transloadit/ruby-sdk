require "test_helper"
require "multi_json"
require "rbconfig"
require "tmpdir"

describe Transloadit::Request do
  it "must allow initialization" do
    request = Transloadit::Request.new "/"
    _(request).must_be_kind_of Transloadit::Request
  end

  describe "when performing a GET" do
    before do
      @request = Transloadit::Request.new "/"
    end

    it "must inspect to the API URL" do
      _(@request.inspect).must_equal @request.url.to_s.inspect
    end

    it "must perform a GET against the resource" do
      VCR.use_cassette "fetch_root" do
        _(@request.get(params: {foo: "bar"})["ok"])
          .must_equal "SERVER_ROOT"
      end
    end

    describe "with secret" do
      before do
        @request.secret = "tehsupersecrettoken"
      end

      it "must inspect to the API URL" do
        _(@request.inspect).must_equal @request.url.to_s.inspect
      end

      it "must perform a GET against the resource" do
        VCR.use_cassette "fetch_root" do
          _(@request.get(params: {foo: "bar"})["ok"])
            .must_equal "SERVER_ROOT"
        end
      end
    end
  end

  describe "when performing a POST" do
    it "must perform a POST against the resource" do
      @request = Transloadit::Request.new("assemblies", "secret")

      VCR.use_cassette "post_assembly" do
        _(@request.post(params: {
          auth: {key: "",
                 expires: (Time.now + 10).utc.strftime("%Y/%m/%d %H:%M:%S+00:00")},
          steps: {encode: {robot: "/video/encode"}}
        })["ok"]).must_equal "ASSEMBLY_COMPLETED"
      end
    end
  end

  describe "when performing a PUT" do
    it "must perform a PUT against the resource" do
      @request = Transloadit::Request.new("templates/55c965a063a311e6ba2d379ef10b28f7", "secret")
      VCR.use_cassette "update_template" do
        _(@request.put(params: {
          name: "foo",
          template: {key: "value"}
        })["ok"]).must_equal "TEMPLATE_UPDATED"
      end
    end
  end

  describe "when performing a DELETE" do
    it "must perform a DELETE against the resource" do
      @request = Transloadit::Request.new("templates/55c965a063a311e6ba2d379ef10b28f7", "secret")

      VCR.use_cassette "delete_template" do
        _(@request.delete["ok"]).must_equal "TEMPLATE_DELETED"
      end
    end
  end

  it "loads request when URI was not previously required" do
    lib_path = File.expand_path("../../../lib", __dir__)

    Dir.mktmpdir do |stub_dir|
      File.write(File.join(stub_dir, "rest-client.rb"), <<~RUBY)
        module RestClient
          class Response; end

          class Resource
            def initialize(*); end
            def [](*); self; end
            def get(*); Response.new; end
            def post(*); Response.new; end
            def put(*); Response.new; end
            def delete(*); Response.new; end
          end

          module Exceptions
            class OpenTimeout < StandardError; end
          end
        end
      RUBY

      File.write(File.join(stub_dir, "multi_json.rb"), <<~RUBY)
        require "json"

        module MultiJson
          def self.dump(value)
            JSON.dump(value)
          end

          def self.load(json)
            JSON.parse(json)
          end
        end
      RUBY

      script = <<~RUBY
        $LOAD_PATH.unshift #{stub_dir.inspect}
        $LOAD_PATH.unshift #{lib_path.inspect}

        begin
          require "transloadit/request"
          Transloadit::Request.new("/")
        rescue StandardError => e
          warn e.full_message
          exit 1
        end
      RUBY

      stdout, stderr, status = Open3.capture3(RbConfig.ruby, "-e", script)
      error_output = stderr.empty? ? stdout : stderr
      assert status.success?, "Expected transloadit/request to load without NameError, got: #{error_output}"
    end
  end
end

describe "signature parity" do
  it "matches transloadit CLI sig output" do
    skip "Parity testing not enabled" unless ENV["TEST_NODE_PARITY"] == "1"

    expires = "2025-01-02T00:00:00.000Z"
    params = {
      auth: {key: "cli-key", expires: expires},
      steps: {encode: {robot: "/video/encode"}}
    }

    cli_result = run_transloadit_sig(params, key: "cli-key", secret: "cli-secret", algorithm: "sha384")
    refute_nil cli_result

    cli_params_json = cli_result["params"]
    request = Transloadit::Request.new("/", "cli-secret")
    ruby_signature = request.send(:signature, cli_params_json)

    assert_equal cli_result["signature"], ruby_signature

    cli_params = JSON.parse(cli_params_json)
    assert_equal "cli-key", cli_params.dig("auth", "key")
    assert_equal expires, cli_params.dig("auth", "expires")
    assert_equal "/video/encode", cli_params.dig("steps", "encode", "robot")
  end
end
