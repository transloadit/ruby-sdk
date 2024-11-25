require "test_helper"

describe Transloadit do
  before do
    @transloadit = Transloadit.new(key: "my-key", secret: "my-secret")
    @workspace = "my-app"
    @template = "test-smart-cdn"
    @input = "inputs/prinsengracht.jpg"
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

    it "uses instance credentials by default" do
      url = @transloadit.signed_smart_cdn_url(
        workspace: @workspace,
        template: @template,
        input: @input
      )
      assert_match(/auth_key=my-key/, url)
    end

    it "allows overriding credentials" do
      url = @transloadit.signed_smart_cdn_url(
        workspace: @workspace,
        template: @template,
        input: @input,
        auth_key: "override-key",
        auth_secret: "override-secret"
      )
      assert_match(/auth_key=override-key/, url)
    end
  end
end
