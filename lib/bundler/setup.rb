# This is not actually required by the actual library
require 'bundler/shared_helpers'

if Bundler::SharedHelpers.in_bundle?
  require 'rubygems'
  require 'bundler'

  Bundler.setup
end