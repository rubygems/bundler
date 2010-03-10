$:.unshift File.expand_path("../lib", __FILE__)

require 'rubygems'
require 'rubygems/specification'
require 'bundler'

spec = Gem::Specification.new do |s|
  s.name     = "bundler"
  s.version  = Bundler::VERSION
  s.authors  = ["Carl Lerche", "Yehuda Katz", "André Arko"]
  s.email    = ["carlhuda@engineyard.com"]
  s.homepage = "http://github.com/carlhuda/bundler"
  s.summary  = "Bundles are fun"

  s.platform = Gem::Platform::RUBY

  s.required_rubygems_version = ">= 1.3.6"

  s.files        = Dir.glob("{bin,lib}/**/*") + %w(LICENSE README.md ROADMAP.md)
  s.executables  = ['bundle']
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

rubyopt = ENV["RUBYOPT"]

%w(master REL_1_3_5 REL_1_3_6).each do |rg|
  Spec::Rake::SpecTask.new("spec_#{rg}") do |t|
    t.spec_files = FileList['spec/**/*_spec.rb']
    t.spec_opts  = %w(-fs --color)
    t.warning    = true
  end

  task "rubygems_#{rg}" do
    unless File.directory?("tmp/rubygems_#{rg}")
      system("git clone git://github.com/jbarnette/rubygems.git tmp/rubygems_#{rg} && cd tmp/rubygems_#{rg} && git reset --hard #{rg}")
    end
    ENV["RUBYOPT"] = "-I#{File.expand_path("tmp/rubygems_#{rg}/lib")} #{rubyopt}"
  end

  task "spec_#{rg}" => "rubygems_#{rg}"

  task :ci => "spec_#{rg}"
end

begin
  require 'rake/gempackagetask'
rescue LoadError
  task(:gem) { $stderr.puts '`gem install rake` to package gems' }
else
  Rake::GemPackageTask.new(spec) do |pkg|
    pkg.gem_spec = spec
  end
  task :gem => :gemspec
end

desc "install the gem locally"
task :install => :package do
  sh %{gem install pkg/#{spec.name}-#{spec.version}}
end

desc "create a gemspec file"
task :gemspec do
  File.open("#{spec.name}.gemspec", "w") do |file|
    file.puts spec.to_ruby
  end
end

task :package => :gemspec
task :default => [:spec, :gemspec]