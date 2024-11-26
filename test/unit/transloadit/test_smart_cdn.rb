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
      assert_match(/test-smart-cdn\/\?auth_key/, url)
    end

    it "uses instance credentials by default" do
      url = @transloadit.signed_smart_cdn_url(
        workspace: @workspace,
        template: @template,
        input: @input,
        expire_at_ms: @expire_at
      )
      assert_match(/auth_key=my-key/, url)
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
      assert_match(/auth_key=override-key/, url)
    end
  end
end
