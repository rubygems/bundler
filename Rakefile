$:.unshift File.expand_path("../lib", __FILE__)

require 'rubygems'
require 'rubygems/specification'
require 'bubble'

spec = Gem::Specification.new do |s|
  s.name     = "bubble"
  s.version  = Bubble::VERSION
  s.authors  = ["Carl Lerche", "Yehuda Katz"]
  s.email    = ["carlhuda@engineyard.com"]
  s.homepage = "http://github.com/carlhuda/bubble"
  s.summary  = "Bubbles are fun"

  s.platform = Gem::Platform::RUBY

  s.required_rubygems_version = ">= 1.3.5"

  s.files        = Dir.glob("{bin,lib}/**/*") + %w(LICENSE README)
  s.executables  = ['bbl']
  s.require_path = 'lib'
end

begin
  require 'spec/rake/spectask'
rescue LoadError
  task :spec do
    $stderr.puts '`gem install rspec` to run specs'
  end
else
  desc "Run specs"
  Spec::Rake::SpecTask.new do |t|
    t.spec_files = FileList['spec/**/*_spec.rb']
    t.spec_opts  = %w(-fs --color)
    t.warning    = true
  end
end

desc "create a gemspec file"
task :gemspec do
  File.open("#{spec.name}.gemspec", 'w') do |file|
    file.puts spec.to_ruby
  end
end

task :default => :spec