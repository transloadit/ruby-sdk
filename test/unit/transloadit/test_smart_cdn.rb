require "test_helper"

describe Transloadit do
  before do
    @transloadit = Transloadit.new(key: "my-key", secret: "my-secret")
    @workspace = "my-app"
    @template = "test-smart-cdn"
    @input = "inputs/prinsengracht.jpg"
    @expire_at = 1732550672867
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
      url = @transloadit.signed_smart_cdn_url(
        workspace: @workspace,
        template: @template,
        input: "",
        expire_at_ms: @expire_at
      )
      assert_equal "https://my-app.tlcdn.com/test-smart-cdn/?auth_key=my-key&exp=1732550672867&sig=sha256%3Ad5e13df4acde8d4aaa0f34534489e54098b5128c54392600ed96dd77669a533e", url
    end

    it "uses instance credentials by default" do
      url = @transloadit.signed_smart_cdn_url(
        workspace: @workspace,
        template: @template,
        input: @input,
        expire_at_ms: @expire_at
      )
      assert_equal "https://my-app.tlcdn.com/test-smart-cdn/inputs%2Fprinsengracht.jpg?auth_key=my-key&exp=1732550672867&sig=sha256%3A8620fc2a22aec6081cde730b7f3f29c0d8083f58a68f62739e642b3c03709139", url
    end

    it "allows overriding credentials" do
      url = @transloadit.signed_smart_cdn_url(
        workspace: @workspace,
        template: @template,
        input: @input,
        expire_at_ms: @expire_at,
        auth_key: "override-key",
        auth_secret: "override-secret"
      )
      assert_equal "https://my-app.tlcdn.com/test-smart-cdn/inputs%2Fprinsengracht.jpg?auth_key=override-key&exp=1732550672867&sig=sha256%3A90734593f8d05e09afc6869d9e37339a85a7041974c133d4663c2376f2736983", url
    end

    it "includes empty width parameter" do
      url = @transloadit.signed_smart_cdn_url(
        workspace: @workspace,
        template: @template,
        input: @input,
        expire_at_ms: @expire_at,
        url_params: {
          width: "",
          height: 200
        }
      )
      assert_equal "https://my-app.tlcdn.com/test-smart-cdn/inputs%2Fprinsengracht.jpg?auth_key=my-key&exp=1732550672867&height=200&width=&sig=sha256%3Aebf562722c504839db97165e657583f74192ac4ab580f1a0dd67d3d868b4ced3", url
    end
  end
end
