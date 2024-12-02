$:.unshift File.dirname(__FILE__)
$:.unshift File.expand_path("../../lib", __FILE__)

if ENV["COVERAGE"] != "0"
  require "simplecov"
  SimpleCov.start do
    add_filter "/test/"
    enable_coverage :branch

    # Use JSON formatter for Codecov
    SimpleCov.formatter = SimpleCov::Formatter::JSONFormatter if ENV["CI"]
  end
end

require "minitest/autorun"
require "transloadit"
require "vcr"

VCR.configure do |c|
  c.cassette_library_dir = "test/fixtures/cassettes"
  c.default_cassette_options = {record: :none}
  c.hook_into :webmock
end

def values_from_post_body(body)
  Addressable::URI.parse("?" + CGI.unescape(body)).query_values
end
