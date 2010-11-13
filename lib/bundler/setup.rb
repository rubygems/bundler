require 'bundler/shared_helpers'

if Bundler::SharedHelpers.in_bundle?
  require 'bundler'
  begin
    Bundler.setup
  rescue Bundler::BundlerError => e
    puts "\e[31m#{e.message}\e[0m"
    puts e.backtrace.join("\n") if ENV["DEBUG"]
    exit e.status_code
  end

  # Add bundler to the load path after disabling system gems
  bundler_lib = File.expand_path("../..", __FILE__)
  $LOAD_PATH.unshift(bundler_lib) unless $LOAD_PATH.include?(bundler_lib)
end
