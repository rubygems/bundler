$:.unshift File.expand_path('..', __FILE__)
$:.unshift File.expand_path('../../lib', __FILE__)

require 'fileutils'
require 'rubygems'
require 'bundler'
require 'spec'

Dir["#{File.expand_path('../support', __FILE__)}/*.rb"].each do |file|
  require file
end

$debug    = false
$show_err = true

Spec::Rubygems.setup
Spec::Path.gem_repo1.rmtree

Spec::Runner.configure do |config|
  config.include Spec::Builders
  config.include Spec::Helpers
  config.include Spec::Indexes
  config.include Spec::Matchers
  config.include Spec::Path
  config.include Spec::Rubygems
  config.include Spec::Platforms

  original_wd       = Dir.pwd
  original_path     = ENV['PATH']
  original_gem_home = ENV['GEM_HOME']

  def pending_jruby_shebang_fix
    pending "JRuby executables do not have a proper shebang" if RUBY_PLATFORM == "java"
  end

  def check(*args)
    # suppresses ruby warnings about "useless use of == in void context"
    # e.g. check foo.should == bar
  end

  config.before :all do
    build_repo1
  end

  config.before :each do
    reset!
    system_gems []
    in_app_root
  end

  config.after :each do
    Gem.platforms = nil
    Dir.chdir(original_wd)
    # Reset ENV
    ENV['PATH']           = original_path
    ENV['GEM_HOME']       = original_gem_home
    ENV['GEM_PATH']       = original_gem_home
    ENV['BUNDLE_PATH']    = nil
    ENV['BUNDLE_GEMFILE'] = nil
  end
end