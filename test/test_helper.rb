$:.unshift File.dirname(__FILE__)
$:.unshift File.expand_path('../../lib', __FILE__)

require 'simplecov'

SimpleCov.start { add_filter '/test/' }

require 'minitest/autorun'
require 'transloadit'
require 'vcr'

VCR.config do |c|
  c.cassette_library_dir     = 'test/fixtures/cassettes'
  c.default_cassette_options = { :record => :new_episodes }
  c.stub_with :webmock
end
