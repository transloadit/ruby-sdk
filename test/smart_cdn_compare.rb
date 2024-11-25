#!/usr/bin/env ruby
puts "Current directory: #{Dir.pwd}"
puts "Load path: #{$LOAD_PATH}"
$LOAD_PATH.unshift File.expand_path('../lib', __dir__)
puts "Updated load path: #{$LOAD_PATH}"
require 'bundler/setup'
puts "Loaded bundler/setup"
require 'transloadit'
puts "Loaded transloadit"
puts "Loading smart_cdn..."
require_relative '../lib/transloadit/smart_cdn'
puts "Loaded smart_cdn"

# Get CLI arguments
expire_at = ARGV[0]
workspace = ARGV[1]
template = ARGV[2]
input = ARGV[3]

puts "Environment variables:"
puts "TRANSLOADIT_KEY: #{ENV['TRANSLOADIT_KEY']}"
puts "TRANSLOADIT_SECRET: #{ENV['TRANSLOADIT_SECRET']}"

# Generate URL using Ruby implementation
url = Transloadit::SmartCDN.signed_url(
  workspace: workspace,
  template: template,
  input: input,
  auth_key: ENV['TRANSLOADIT_KEY'],
  auth_secret: ENV['TRANSLOADIT_SECRET'],
  expire_at_ms: expire_at.to_i
)

puts "Ruby: #{url}"

# Execute Node.js implementation and capture output
node_url = `tsx dev/smartcdn-sig.ts #{expire_at} #{workspace} #{template} #{input}`.strip
puts "Node: #{node_url}"

# Compare outputs
if url == node_url
  puts "\n✅ Outputs match!"
  exit 0
else
  puts "\n❌ Outputs differ!"
  exit 1
end
