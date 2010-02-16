$:.unshift File.expand_path('..', __FILE__)
$:.unshift File.expand_path('../../lib', __FILE__)

require 'fileutils'
require 'rubygems'
require 'bundler'
require 'spec'

Dir["#{File.expand_path('../support', __FILE__)}/*.rb"].each do |file|
  require file
end

Spec::Rubygems.setup
FileUtils.rm_rf(Spec::Path.gem_repo1)

Spec::Runner.configure do |config|
  config.include Spec::Builders
  config.include Spec::Helpers
  config.include Spec::Matchers
  config.include Spec::Path
  config.include Spec::Rubygems
  config.include Spec::Platforms

  original_wd       = Dir.pwd
  original_path     = ENV['PATH']
  original_gem_home = ENV['GEM_HOME']

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
    # Reset ENV
    ENV['PATH']           = original_path
    ENV['GEM_HOME']       = original_gem_home
    ENV['GEM_PATH']       = original_gem_home
    ENV['BUNDLE_PATH']    = nil
    ENV['BUNDLE_GEMFILE'] = nil
  end
end