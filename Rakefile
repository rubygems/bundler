# coding:utf-8
$:.unshift File.expand_path("../lib", __FILE__)

require 'rubygems'
require 'rubygems/specification'
require 'bundler'

def gemspec
  @gemspec ||= begin
    file = File.expand_path('../bundler.gemspec', __FILE__)
    eval(File.read(file), binding, file)
  end
end

def sudo?
  ENV['BUNDLER_SUDO_TESTS']
end

begin
  require 'rspec/core/rake_task'

  task :clear_tmp do
    FileUtils.rm_rf(File.expand_path("../tmp", __FILE__))
  end

  desc "Run specs"
  RSpec::Core::RakeTask.new do |t|
    t.spec_opts  = %w(-fs --color)
    t.warning    = true
  end
  task :spec

  namespace :spec do
    task :sudo do
      ENV['BUNDLER_SUDO_TESTS'] = '1'
    end

    task :clean do
      if sudo?
        system "sudo rm -rf #{File.expand_path('../tmp', __FILE__)}"
      else
        rm_rf 'tmp'
      end
    end

    desc "Run the full spec suite including SUDO tests"
    task :full => ["sudo", "clean", "spec"]
  end
rescue LoadError
  raise 'Run `gem install rspec` to be able to run specs'
end


# Rubygems 1.3.5, 1.3.6, and HEAD specs
rubyopt = ENV["RUBYOPT"]
%w(master REL_1_3_5 REL_1_3_6).each do |rg|
  desc "Run specs with Rubygems #{rg}"
  RSpec::Core::RakeTask.new("spec_gems_#{rg}") do |t|
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
  RSpec::Core::RakeTask.new("spec_ruby_#{ruby}") do |t|
    t.spec_opts  = %w(-fs --color)
    t.warning    = true
    #t.ruby_cmd   = ruby_cmd
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
  Rake::GemPackageTask.new(gemspec) do |pkg|
    pkg.gem_spec = gemspec
  end
  task :gem => :gemspec
end

desc "install the gem locally"
task :install => :package do
  sh %{gem install pkg/#{gemspec.name}-#{gemspec.version}}
end

desc "validate the gemspec"
task :gemspec do
  gemspec.validate
end

task :package => :gemspec
task :default => :spec
