require 'rubygems'
require 'rake'

begin
  require 'jeweler'
  Jeweler::Tasks.new do |gem|
    gem.name = "samuel"
    gem.summary = %Q{An automatic logger for HTTP requests in Ruby}
    gem.description = %Q{An automatic logger for HTTP requests in Ruby. Adds Net::HTTP request logging to your Rails logs, and more.}
    gem.email = "chris@kampers.net"
    gem.homepage = "http://github.com/chrisk/samuel"
    gem.authors = ["Chris Kampmeier"]
    gem.rubyforge_project = "samuel"
    gem.add_development_dependency "thoughtbot-shoulda"
    gem.add_development_dependency "yard"
    gem.add_development_dependency "mocha"
    gem.add_development_dependency "fakeweb"
  end
  Jeweler::GemcutterTasks.new
  Jeweler::RubyforgeTasks.new do |rubyforge|
    rubyforge.doc_task = "yardoc"
  end
rescue LoadError
  puts "Jeweler (or a dependency) not available. Install it with: sudo gem install jeweler"
end

require 'rake/testtask'
Rake::TestTask.new(:test) do |test|
  test.libs << 'lib' << 'test'
  test.pattern = 'test/**/*_test.rb'
  test.verbose = false
  test.warning = true
end

begin
  require 'rcov/rcovtask'
  Rcov::RcovTask.new do |test|
    test.libs << 'test'
    test.pattern = 'test/**/*_test.rb'
    test.rcov_opts << "--sort coverage"
    test.rcov_opts << "--exclude gems"
    test.verbose = false
    test.warning = true
  end
rescue LoadError
  task :rcov do
    abort "RCov is not available. In order to run rcov, you must: sudo gem install spicycode-rcov"
  end
end

task :test => :check_dependencies

task :default => :test

begin
  require 'yard'
  YARD::Rake::YardocTask.new
rescue LoadError
  task :yardoc do
    abort "YARD is not available. In order to run yardoc, you must: sudo gem install yard"
  end
end
