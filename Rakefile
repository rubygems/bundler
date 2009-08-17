require 'rubygems' unless ENV['NO_RUBYGEMS']
require 'rake/gempackagetask'
require 'rubygems/specification'
require 'date'
require 'spec/rake/spectask'

spec = Gem::Specification.new do |s|
  s.name    = "bundler"
  s.version = "0.4.0"
  s.author  = "Yehuda Katz"
  s.email   = "wycats@gmail.com"
  s.homepage = "http://github.com/wycats/bundler"
  s.description = s.summary = "An easy way to vendor gem dependencies"

  s.platform = Gem::Platform::RUBY
  s.has_rdoc = true
  s.extra_rdoc_files = ["README.markdown", "LICENSE"]

  s.required_rubygems_version = ">= 1.3.5"

  s.require_path = 'lib'
  s.files = %w(LICENSE README.markdown Rakefile) + Dir.glob("lib/**/*")
end

task :default => :spec

desc "Run specs"
Spec::Rake::SpecTask.new do |t|
  t.spec_files = FileList['spec/**/*_spec.rb'] - FileList['spec/fixtures/**/*_spec.rb']
  t.spec_opts = %w(-fs --color)
end


Rake::GemPackageTask.new(spec) do |pkg|
  pkg.gem_spec = spec
end

desc "install the gem locally"
task :install => [:package] do
  sh %{gem install pkg/#{spec.name}-#{spec.version}}
end

desc "create a gemspec file"
task :make_spec do
  File.open("#{spec.name}.gemspec", "w") do |file|
    file.puts spec.to_ruby
  end
end