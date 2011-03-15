$:.unshift File.expand_path('../lib', __FILE__)

require 'transloadit/version'

Gem::Specification.new do |gem|
  gem.name     = 'transloadit'
  gem.version  = Transloadit::VERSION
  gem.platform = Gem::Platform::RUBY
  
  gem.authors  = %w{ Stephen Touset }
  gem.email    = %w{ stephen@touset.org }
  gem.homepage = 'http://github.com/transloadit/ruby-sdk/'
  
  gem.summary     = 'Official Ruby gem for Transloadit'
  gem.description = 'The transloadit gem allows you to automate uploading files through the Transloadit REST API'
  
  gem.required_rubygems_version = '>= 1.3.6'
  gem.rubyforge_project         = 'transloadit'
  
  gem.files         = `git ls-files`.split("\n")
  gem.test_files    = `git ls-files -- {test,spec,features}/*`.split("\n")
  gem.require_paths = %w{ lib }
  
  gem.add_dependency 'rest-client'
  gem.add_dependency 'json'
  
  gem.add_development_dependency 'rake'
  gem.add_development_dependency 'minitest' # needed for < 1.9.2
  gem.add_development_dependency 'simplecov'
  
  gem.add_development_dependency 'vcr'
  gem.add_development_dependency 'webmock'

  gem.add_development_dependency 'yard'
  gem.add_development_dependency 'rdiscount' # for YARD rdoc formatting
end
