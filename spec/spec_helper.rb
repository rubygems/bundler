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

tmpdir = File.expand_path('../../tmp', __FILE__)
FileUtils.mkdir_p(tmpdir) unless File.exist?(tmpdir)
Dir["#{tmpdir}/*"].each do |file|
  FileUtils.rm_rf file
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