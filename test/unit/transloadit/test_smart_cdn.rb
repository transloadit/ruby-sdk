require "test_helper"

describe Transloadit::SmartCDN do
  before do
    @auth_key = "my-key"
    @auth_secret = "my-secret"
    @workspace = "my-app"
    @template = "test-smart-cdn"
    @input = "inputs/prinsengracht.jpg"
  end

  it "requires workspace" do
    assert_raises ArgumentError, "workspace is required" do
      Transloadit::SmartCDN.signed_url(
        workspace: nil,
        template: @template,
        input: @input,
        auth_key: @auth_key,
        auth_secret: @auth_secret
      )
    end
  end

  it "requires template" do
    assert_raises ArgumentError, "template is required" do
      Transloadit::SmartCDN.signed_url(
        workspace: @workspace,
        template: nil,
        input: @input,
        auth_key: @auth_key,
        auth_secret: @auth_secret
      )
    end
  end

  it "requires input" do
    assert_raises ArgumentError, "input is required" do
      Transloadit::SmartCDN.signed_url(
        workspace: @workspace,
        template: @template,
        input: nil,
        auth_key: @auth_key,
        auth_secret: @auth_secret
      )
    end
  end
end
