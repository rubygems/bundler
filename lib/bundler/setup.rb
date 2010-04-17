# This is not actually required by the actual library
# loads the bundled environment
require 'bundler/shared_helpers'

if Bundler::SharedHelpers.in_bundle?
  env_file = Bundler::SharedHelpers.env_file
  if env_file.exist?
    require env_file
  else
    require 'bundler'
    begin
      Bundler.setup
    rescue Bundler::BundlerError => e
      puts "\e[31m#{e.message}\e[0m"
      exit e.status_code
    end
  end
end