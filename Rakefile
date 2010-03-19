# coding:utf-8
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

  s.add_development_dependency "rspec"

  s.files        = Dir.glob("{bin,lib}/**/*") + %w(LICENSE README.md ROADMAP.md CHANGELOG.md)
  s.executables  = ['bundle']
  s.require_path = 'lib'
end

begin
  require 'spec/rake/spectask'
rescue LoadError
  raise 'Run `gem install rspec` to be able to run specs'
else
  task :clear_tmp do
    FileUtils.rm_rf(File.expand_path("../tmp", __FILE__))
  end

  desc "Run specs"
  Spec::Rake::SpecTask.new do |t|
    t.spec_files = FileList['spec/**/*_spec.rb']
    t.spec_opts  = %w(-fs --color)
    t.warning    = true
  end
  task :spec => :clear_tmp
end


# Rubygems 1.3.5, 1.3.6, and HEAD specs
rubyopt = ENV["RUBYOPT"]
%w(master REL_1_3_6).each do |rg|
  desc "Run specs with Rubygems #{rg}"
  Spec::Rake::SpecTask.new("spec_gems_#{rg}") do |t|
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

  task "spec_gems_#{rg}" => "rubygems_#{rg}"
  task :ci => "spec_gems_#{rg}"
end


# Ruby 1.8.6, 1.8.7, and 1.9.2 specs
task "ensure_rvm" do
  raise "RVM is not available" unless File.exist?(File.expand_path("~/.rvm/scripts/rvm"))
end

%w(1.8.6-p399 1.8.7-p249 1.9.2-head).each do |ruby|
  ruby_cmd = File.expand_path("~/.rvm/bin/ruby-#{ruby}")

  desc "Run specs on Ruby #{ruby}"
  Spec::Rake::SpecTask.new("spec_ruby_#{ruby}") do |t|
    t.spec_files = FileList['spec/**/*_spec.rb']
    t.spec_opts  = %w(-fs --color)
    t.warning    = true
    t.ruby_cmd   = ruby_cmd
  end

  task "ensure_ruby_#{ruby}" do
    raise "Could not find Ruby #{ruby} at #{ruby_cmd}" unless File.exist?(ruby_cmd)
  end

  task "ensure_ruby_#{ruby}" => "ensure_rvm"
  task "spec_ruby_#{ruby}" => "ensure_ruby_#{ruby}"
  task :ci => "spec_ruby_#{ruby}"
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