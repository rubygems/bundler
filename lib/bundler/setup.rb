# This is not actually required by the actual library
require 'bundler/shared_helpers'

if Bundler::SharedHelpers.in_bundle?
  locked_env = Bundler::SharedHelpers.default_gemfile.join("../.bundle/environment.rb")
  if locked_env.exist?
    require locked_env
  else
    require 'rubygems'
    require 'bundler'
    Bundler.setup
  end
end