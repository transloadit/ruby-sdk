require "test_helper"
require "json"
require "open3"

describe Transloadit do
  # Only run these tests if we're in CI or explicitly requested
  if ENV["TEST_NODE_PARITY"] == "1"
    before do
      @transloadit = Transloadit.new(key: "my-key", secret: "my-secret")
      @workspace = "my-app"
      @template = "test-smart-cdn"
      @input = "inputs/prinsengracht.jpg"
      @expire_at = 1732550672867

      # Fail if tsx is not available but was explicitly requested
      unless system("which tsx > /dev/null 2>&1")
        raise "tsx is required for node parity tests. Please install with: npm install -g tsx"
      end
    end

    def run_node_script(params)
      script_path = File.expand_path("./node-smartcdn-sig", __dir__)
      json_input = JSON.dump(params)
      stdout, stderr, status = Open3.capture3("tsx #{script_path}", stdin_data: json_input)
      raise "Node script failed: #{stderr}" unless status.success?
      stdout.strip
    end

    describe "#signed_smart_cdn_url" do
      it "generates urls that match node implementation" do
        params = {
          workspace: @workspace,
          template: @template,
          input: @input,
          expire_at_ms: @expire_at
        }

        url = @transloadit.signed_smart_cdn_url(**params)
        node_url = run_node_script(params)
        assert_equal node_url, url
      end

      it "handles url parameters the same as node" do
        params = {
          workspace: @workspace,
          template: @template,
          input: @input,
          expire_at_ms: @expire_at,
          url_params: {
            width: 100,
            height: 200
          }
        }

        url = @transloadit.signed_smart_cdn_url(**params)
        node_url = run_node_script(params)
        assert_equal node_url, url
      end

      it "handles nil values in parameters the same as node" do
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
        node_url = run_node_script(params)
        assert_equal node_url, url
      end

      it "handles empty string values in parameters the same as node" do
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
        node_url = run_node_script(params)
        assert_equal node_url, url
      end

      it "handles array values in parameters the same as node" do
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
        node_url = run_node_script(params)
        assert_equal node_url, url
      end

      it "handles empty input string the same as node" do
        params = {
          workspace: @workspace,
          template: @template,
          input: "",
          expire_at_ms: @expire_at
        }

        url = @transloadit.signed_smart_cdn_url(**params)
        node_url = run_node_script(params)
        assert_equal node_url, url
      end
    end
  end
end
