require "test_helper"

describe Transloadit do
  # Only run these tests if we're in CI or explicitly requested
  if ENV["CI"] == "true" || ENV["TEST_NODE_PARITY"] == "true"
    before do
      @transloadit = Transloadit.new(key: "my-key", secret: "my-secret")
      @workspace = "my-app"
      @template = "test-smart-cdn"
      @input = "inputs/prinsengracht.jpg"
      @expire_at = 1732550672867

      # Skip if tsx is not available
      skip "tsx not available" unless system("which tsx > /dev/null 2>&1")
    end

    describe "#signed_smart_cdn_url" do
      it "generates urls that match node implementation" do
        url = @transloadit.signed_smart_cdn_url(
          workspace: @workspace,
          template: @template,
          input: @input,
          expire_at_ms: @expire_at
        )

        node_url = `tsx #{File.expand_path("./node-smartcdn-sig", __dir__)} #{@expire_at} #{@workspace} #{@template} #{@input}`.strip
        assert_equal node_url, url
      end

      it "handles url parameters the same as node" do
        url = @transloadit.signed_smart_cdn_url(
          workspace: @workspace,
          template: @template,
          input: @input,
          expire_at_ms: @expire_at,
          url_params: {
            width: 100,
            height: 200
          }
        )

        node_url = `tsx #{File.expand_path("./node-smartcdn-sig", __dir__)} #{@expire_at} #{@workspace} #{@template} #{@input} width=100 height=200`.strip
        assert_equal node_url, url
      end

      it "handles nil values in parameters the same as node" do
        url = @transloadit.signed_smart_cdn_url(
          workspace: @workspace,
          template: @template,
          input: @input,
          expire_at_ms: @expire_at,
          url_params: {
            width: nil,
            height: 200
          }
        )

        node_url = `tsx #{File.expand_path("./node-smartcdn-sig", __dir__)} #{@expire_at} #{@workspace} #{@template} #{@input} width=null height=200`.strip
        assert_equal node_url, url
      end
    end
  end
end
