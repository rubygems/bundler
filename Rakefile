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

spec_file = "#{spec.name}.gemspec"
desc "Create #{spec_file}"
file spec_file => "Rakefile" do
  File.open(spec_file, "w") do |file|
    file.puts spec.to_ruby
  end
end

begin
  require 'rake/gempackagetask'
rescue LoadError
  task(:gem) { $stderr.puts '`gem install rake` to package gems' }
else
  Rake::GemPackageTask.new(spec) do |pkg|
    pkg.gem_spec = spec
  end
  task :gem => spec_file
end

desc "install the gem locally"
task :install => :package do
  sh %{gem install pkg/#{spec.name}-#{spec.version}}
end

desc "create a gemspec file"
task :gemspec => spec_file

task :default => :spec