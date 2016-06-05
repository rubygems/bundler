# frozen_string_literal: true
$:.unshift File.expand_path("..", __FILE__)
$:.unshift File.expand_path("../../lib", __FILE__)

require "bundler/psyched_yaml"
require "fileutils"
require "uri"
require "digest/sha1"

begin
  require "rubygems"
  spec = Gem::Specification.load("bundler.gemspec")
  rspec = spec.dependencies.find {|d| d.name == "rspec" }
  gem "rspec", rspec.requirement.to_s
  require "rspec"
rescue LoadError
  abort "Run rake spec:deps to install development dependencies"
end

require "bundler"

# Require the correct version of popen for the current platform
if RbConfig::CONFIG["host_os"] =~ /mingw|mswin/
  begin
    require "win32/open3"
  rescue LoadError
    abort "Run `gem install win32-open3` to be able to run specs"
  end
else
  require "open3"
end

Dir["#{File.expand_path("../support", __FILE__)}/*.rb"].each do |file|
  require file unless file =~ %r{fakeweb/.*\.rb}
end

$debug    = false
$show_err = true

Spec::Rubygems.setup
FileUtils.rm_rf(Spec::Path.gem_repo1)
ENV["RUBYOPT"] = "#{ENV["RUBYOPT"]} -r#{Spec::Path.root}/spec/support/hax.rb"
ENV["BUNDLE_SPEC_RUN"] = "true"

# Don't wrap output in tests
ENV["THOR_COLUMNS"] = "10000"

Spec::CodeClimate.setup

RSpec.configure do |config|
  config.include Spec::Builders
  config.include Spec::Helpers
  config.include Spec::Indexes
  config.include Spec::Matchers
  config.include Spec::Path
  config.include Spec::Rubygems
  config.include Spec::Platforms
  config.include Spec::Sudo
  config.include Spec::Permissions

  # Enable flags like --only-failures and --next-failure
  config.example_status_persistence_file_path = ".rspec_status"

  if ENV["BUNDLER_SUDO_TESTS"] && Spec::Sudo.present?
    config.filter_run :sudo => true
  else
    config.filter_run_excluding :sudo => true
  end

  if ENV["BUNDLER_REALWORLD_TESTS"]
    config.filter_run :realworld => true
  else
    config.filter_run_excluding :realworld => true
  end

  config.filter_run_excluding :ruby => LessThanProc.with(RUBY_VERSION)
  config.filter_run_excluding :rubygems => LessThanProc.with(Gem::VERSION)
  config.filter_run_excluding :rubygems_master => (ENV["RGV"] != "master")

  config.filter_run :focused => true unless ENV["CI"]
  config.run_all_when_everything_filtered = true

  original_wd  = Dir.pwd
  original_env = ENV.to_hash

  def pending_jruby_shebang_fix
    pending "JRuby executables do not have a proper shebang" if RUBY_PLATFORM == "java"
  end

  config.expect_with :rspec do |c|
    c.syntax = :expect
  end

  config.before :all do
    build_repo1
  end

  config.before :each do
    reset!
    system_gems []
    in_app_root
  end

  config.after :each do |example|
    puts @out if defined?(@out) && example.exception

    Dir.chdir(original_wd)
    ENV.replace(original_env)
  end
end
