require "test_helper"
require "json"
require "open3"

describe Transloadit do
  before do
    @auth_key = "my-key"
    @auth_secret = "my-secret"
    @transloadit = Transloadit.new(key: @auth_key, secret: @auth_secret)
    @workspace = "my-app"
    @template = "test-smart-cdn"
    @input = "inputs/prinsengracht.jpg"
    @expire_at = 1732550672867
  end

  def run_node_script(params)
    return unless ENV["TEST_NODE_PARITY"] == "1"
    script_path = File.expand_path("./node-smartcdn-sig", __dir__)
    json_input = JSON.dump(params)
    stdout, stderr, status = Open3.capture3("tsx #{script_path}", stdin_data: json_input)
    raise "Node script failed: #{stderr}" unless status.success?
    stdout.strip
  end

  describe "#signed_smart_cdn_url" do
    it "requires workspace" do
      assert_raises ArgumentError, "workspace is required" do
        @transloadit.signed_smart_cdn_url(
          workspace: nil,
          template: @template,
          input: @input
        )
      end
    end

    it "requires template" do
      assert_raises ArgumentError, "template is required" do
        @transloadit.signed_smart_cdn_url(
          workspace: @workspace,
          template: nil,
          input: @input
        )
      end
    end

    it "requires input" do
      assert_raises ArgumentError, "input is required" do
        @transloadit.signed_smart_cdn_url(
          workspace: @workspace,
          template: @template,
          input: nil
        )
      end
    end

    it "allows empty input string" do
      params = {
        workspace: @workspace,
        template: @template,
        input: "",
        expire_at_ms: @expire_at
      }
      url = @transloadit.signed_smart_cdn_url(**params)
      assert_equal "https://my-app.tlcdn.com/test-smart-cdn/?auth_key=my-key&exp=1732550672867&sig=sha256%3Ad5e13df4acde8d4aaa0f34534489e54098b5128c54392600ed96dd77669a533e", url

      if (node_url = run_node_script(params.merge(auth_key: "my-key", auth_secret: "my-secret"))
        assert_equal node_url, url
      end
    end

    it "uses instance credentials" do
      params = {
        workspace: @workspace,
        template: @template,
        input: @input,
        expire_at_ms: @expire_at
      }
      url = @transloadit.signed_smart_cdn_url(**params)
      assert_equal "https://my-app.tlcdn.com/test-smart-cdn/inputs%2Fprinsengracht.jpg?auth_key=my-key&exp=1732550672867&sig=sha256%3A8620fc2a22aec6081cde730b7f3f29c0d8083f58a68f62739e642b3c03709139", url

      if (node_url = run_node_script(params.merge(auth_key: "my-key", auth_secret: "my-secret"))
        assert_equal node_url, url
      end
    end

    it "includes empty width parameter" do
      params = {
        workspace: @workspace,
        template: @template,
        input: @input,
        expire_at_ms: @expire_at,
        url_params: {
          width: "",
          height: 200
        }
      }
      url = @transloadit.signed_smart_cdn_url(**params)
      assert_equal "https://my-app.tlcdn.com/test-smart-cdn/inputs%2Fprinsengracht.jpg?auth_key=my-key&exp=1732550672867&height=200&width=&sig=sha256%3Aebf562722c504839db97165e657583f74192ac4ab580f1a0dd67d3d868b4ced3", url

      if (node_url = run_node_script(params.merge(auth_key: "my-key", auth_secret: "my-secret"))
        assert_equal node_url, url
      end
    end

    it "handles nil values in parameters" do
      params = {
        workspace: @workspace,
        template: @template,
        input: @input,
        expire_at_ms: @expire_at,
        url_params: {
          width: nil,
          height: 200
        }
      }
      url = @transloadit.signed_smart_cdn_url(**params)
      assert_equal "https://my-app.tlcdn.com/test-smart-cdn/inputs%2Fprinsengracht.jpg?auth_key=my-key&exp=1732550672867&height=200&sig=sha256%3Ad6897a0cb527a14eaab13c54b06f53527797c553d8b7e5d0b1a5df237212f083", url

      if (node_url = run_node_script(params.merge(auth_key: "my-key", auth_secret: "my-secret"))
        assert_equal node_url, url
      end
    end

    it "handles array values in parameters" do
      params = {
        workspace: @workspace,
        template: @template,
        input: @input,
        expire_at_ms: @expire_at,
        url_params: {
          tags: ["landscape", "amsterdam", nil, ""],
          height: 200
        }
      }
      url = @transloadit.signed_smart_cdn_url(**params)
      assert_equal "https://my-app.tlcdn.com/test-smart-cdn/inputs%2Fprinsengracht.jpg?auth_key=my-key&exp=1732550672867&height=200&tags=landscape&tags=amsterdam&tags=&sig=sha256%3Aff46eb0083d64b250b2e4510380e333f67da855b2401493dee7a706a47957d3f", url

      if (node_url = run_node_script(params.merge(auth_key: "my-key", auth_secret: "my-secret"))
        assert_equal node_url, url
      end
    end
  end
end
