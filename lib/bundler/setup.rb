# This is not actually required by the actual library
# loads the bundled environment
require 'bundler/shared_helpers'

if Bundler::SharedHelpers.in_bundle?
  require 'bundler'
  begin
    Bundler.setup
  rescue Bundler::BundlerError => e
    puts "\e[31m#{e.message}\e[0m"
    exit e.status_code
  end
end