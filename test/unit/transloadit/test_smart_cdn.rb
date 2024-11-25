require 'test_helper'

describe Transloadit::SmartCDN do
  before do
    @auth_key = 'my-key'
    @auth_secret = 'my-secret'
    @workspace = 'my-app'
    @template = 'test-smart-cdn'
    @input = 'inputs/prinsengracht.jpg'
    @expire_at = 1732550672867
  end

  it 'generates correct signed urls' do
    url = Transloadit::SmartCDN.signed_url(
      workspace: @workspace,
      template: @template,
      input: @input,
      auth_key: @auth_key,
      auth_secret: @auth_secret,
      expire_at_ms: @expire_at
    )

    expected_url = 'https://my-app.tlcdn.com/test-smart-cdn/inputs%2Fprinsengracht.jpg?auth_key=my-app&exp=1732550672867&sig=sha256%3A44e74094d8eb12598640ca339b773e1e0366365f9ba652ec2099da79d6efae1b'
    assert_equal expected_url, url
  end

  it 'handles url parameters' do
    url = Transloadit::SmartCDN.signed_url(
      workspace: @workspace,
      template: @template,
      input: @input,
      auth_key: @auth_key,
      auth_secret: @auth_secret,
      expire_at_ms: @expire_at,
      url_params: {
        width: 100,
        height: 200
      }
    )

    assert_match(/width=100/, url)
    assert_match(/height=200/, url)
  end

  it 'requires workspace' do
    assert_raises(ArgumentError) do
      Transloadit::SmartCDN.signed_url(
        workspace: '',
        template: @template,
        input: @input,
        auth_key: @auth_key,
        auth_secret: @auth_secret
      )
    end
  end
end
