$:.unshift File.dirname(__FILE__)
$:.unshift File.expand_path("../../lib", __FILE__)

if ENV["COVERAGE"] != "0"
  require "simplecov"
  SimpleCov.start do
    add_filter "/test/"
    enable_coverage :branch
  end

  require "simplecov-cobertura"
  SimpleCov.formatter = SimpleCov::Formatter::CoberturaFormatter
end

require "minitest/autorun"
require "transloadit"
require "vcr"
require "open3"
require "json"

VCR.configure do |c|
  c.cassette_library_dir = "test/fixtures/cassettes"
  c.default_cassette_options = {record: :none}
  c.hook_into :webmock
end

def values_from_post_body(body)
  Addressable::URI.parse("?" + CGI.unescape(body)).query_values
end

module TransloaditCliHelpers
  TRANSLOADIT_CLI_PACKAGE = ENV.fetch("TRANSLOADIT_CLI_PACKAGE", "transloadit@4.0.5")

  def run_transloadit_cli(command, payload, key:, secret:, algorithm: nil)
    return nil unless ENV["TEST_NODE_PARITY"] == "1"

    env = {
      "TRANSLOADIT_KEY" => key,
      "TRANSLOADIT_SECRET" => secret,
      "TRANSLOADIT_AUTH_KEY" => key,
      "TRANSLOADIT_AUTH_SECRET" => secret
    }

    args = [
      "npm", "exec", "--yes", "--package", TRANSLOADIT_CLI_PACKAGE, "--",
      "transloadit", command
    ]
    args += ["--algorithm", algorithm] if algorithm

    stdout, stderr, status = Open3.capture3(env, *args, stdin_data: JSON.dump(payload))
    raise "transloadit CLI #{command} failed: #{stderr}" unless status.success?

    stdout.strip
  end

  def run_transloadit_smart_sig(payload, key:, secret:)
    cli_payload = {
      workspace: payload.fetch(:workspace),
      template: payload.fetch(:template),
      input: payload.fetch(:input)
    }
    cli_payload[:url_params] = payload[:url_params] if payload.key?(:url_params)
    cli_payload[:expire_at_ms] = payload[:expire_at_ms] if payload.key?(:expire_at_ms)

    run_transloadit_cli("smart_sig", cli_payload, key: key, secret: secret)
  end

  def run_transloadit_sig(payload, key:, secret:, algorithm: nil)
    output = run_transloadit_cli("sig", payload, key: key, secret: secret, algorithm: algorithm)
    output && JSON.parse(output)
  end
end

Minitest::Test.include(TransloaditCliHelpers)
