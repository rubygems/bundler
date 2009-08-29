$:.unshift File.expand_path(File.join(File.dirname(__FILE__)))
$:.unshift File.expand_path(File.join(File.dirname(__FILE__), '..', 'lib'))
require "pp"
require "rubygems"
require "bundler"
require "spec"
require "rbconfig"
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

  config.before(:each) do
    @log_output = StringIO.new
    Bundler.logger.instance_variable_set("@logdev", Logger::LogDevice.new(@log_output))
    reset!
  end

  config.after(:each) do
    Dir.chdir(original_wd)
  end
end
