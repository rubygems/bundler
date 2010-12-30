require 'rubygems'
require 'rake'

version = '1.3.0'

begin
  require 'jeweler'
  Jeweler::Tasks.new do |gem|
    gem.name = "fakeweb"
    gem.rubyforge_project = "fakeweb"
    gem.version = version
    gem.summary = "A tool for faking responses to HTTP requests"
    gem.description = "FakeWeb is a helper for faking web requests in Ruby. It works at a global level, without modifying code or writing extensive stubs."
    gem.email = ["chris@kampers.net", "romeda@gmail.com"]
    gem.authors = ["Chris Kampmeier", "Blaine Cook"]
    gem.homepage = "http://github.com/chrisk/fakeweb"
    gem.add_development_dependency "mocha", ">= 0.9.5"
  end
rescue LoadError
  puts "Jeweler (or a dependency) not available. Install it with: gem install jeweler"
end


require 'rake/testtask'
Rake::TestTask.new(:test) do |test|
  test.test_files = FileList["test/**/*.rb"].exclude("test/test_helper.rb", "test/vendor")
  test.libs << "test"
  test.verbose = false
  test.warning = true
end

task :default => [:check_dependencies, :test]


begin
  require 'rcov/rcovtask'
  Rcov::RcovTask.new do |t|
    t.test_files = FileList["test/**/*.rb"].exclude("test/test_helper.rb", "test/vendor")
    t.libs << "test"
    t.rcov_opts << "--sort coverage"
    t.rcov_opts << "--exclude gems"
    t.warning = true
  end
rescue LoadError
  print "rcov support disabled "
  if RUBY_PLATFORM =~ /java/
    puts "(running under JRuby)"
  else
    puts "(install RCov to enable the `rcov` task)"
  end
end


begin
  require 'sdoc'
  require 'rdoc/task'
  Rake::RDocTask.new do |rdoc|
    rdoc.main = "README.rdoc"
    rdoc.rdoc_files.include("README.rdoc", "CHANGELOG", "LICENSE.txt", "lib/*.rb")
    rdoc.title = "FakeWeb #{version} API Documentation"
    rdoc.rdoc_dir = "doc"
    rdoc.template = "direct"
    rdoc.options << "--line-numbers" << "--show-hash" << "--charset=utf-8"
  end
rescue LoadError
  puts "SDoc (or a dependency) not available. Install it with: gem install sdoc"
end
