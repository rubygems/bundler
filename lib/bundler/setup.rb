# This is not actually required by the actual library
# loads the bundled environment
require 'bundler/shared_helpers'

if Bundler::SharedHelpers.in_bundle?
  env_file = Bundler::SharedHelpers.env_file
  if env_file.exist?
    require env_file
    Bundler.setup if defined?(Bundler::GEM_LOADED)
  else
    require 'bundler'
    begin
      Bundler.setup
    rescue Bundler::BundlerError => e
      puts "\e[31m#{e.message}\e[0m"
      exit e.status_code
    end
  end

  # Add bundler to the load path after disabling system gems
  bundler_lib = File.expand_path("../..", __FILE__)
  $LOAD_PATH.unshift(bundler_lib) unless $LOAD_PATH.include?(bundler_lib)
end