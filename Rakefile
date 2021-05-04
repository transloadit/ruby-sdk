require "bundler/gem_tasks"
require "rake/testtask"

Rake::TestTask.new do |test|
  test.libs << "test"
  test.pattern = "test/**/test_*.rb"
end

begin
  require "yard"
  require "yard/rake/yardoc_task"

  YARD::Rake::YardocTask.new :doc do |yard|
    yard.options = %w[
      --title Transloadit
      --readme README.md
      --markup rdoc
    ]
  end
rescue
  desc "You need the `yard` gem to generate documentation"
  task :doc
end

task default: :test
