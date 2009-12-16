$:.unshift File.expand_path(File.join(File.dirname(__FILE__)))
$:.unshift File.expand_path(File.join(File.dirname(__FILE__), '..', 'lib'))

require "pp"
require "rubygems"
require "bundler"
require "spec"
require "rbconfig"

Gem.clear_paths

root = File.expand_path("../..", __FILE__)
FileUtils.rm_rf("#{root}/tmp/repos")
`rake -f #{root}/Rakefile spec:setup`
ENV['GEM_HOME'], ENV['GEM_PATH'] = "#{root}/tmp/rg_deps", "#{root}/tmp/rg_deps"

Dir[File.join(File.dirname(__FILE__), 'support', '*.rb')].each do |file|
  require file
end

Spec::Runner.configure do |config|
  config.include Spec::Builders
  config.include Spec::Matchers
  config.include Spec::Helpers
  config.include Spec::PathUtils

  original_wd = Dir.pwd

  # No rubygems output messages
  Gem::DefaultUserInteraction.ui = Gem::SilentUI.new

  config.before(:all) do
    build_repo1
  end

  config.before(:each) do
    @_build_path = nil
    @log_output  = StringIO.new
    Bundler.logger.instance_variable_set("@logdev", Logger::LogDevice.new(@log_output))
    reset!
  end

  config.after(:each) do
    Dir.chdir(original_wd)
  end
end