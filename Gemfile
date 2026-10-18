source "https://rubygems.org"

gem "rake"
gem "minitest"
gem "simplecov"
gem "simplecov-cobertura"

# Ruby 3.1 resolves MultiJson 1.19, which cannot parse JSON 3 (ruby-sdk#89).
# Keep its test bundle compatible without restricting consumers on newer Rubies.
gem "json", "< 3.0" if RUBY_VERSION.start_with?("3.1.")

gemspec
