require 'bundler/shared_helpers'
require 'bundler/friendly_errors'

if Bundler::SharedHelpers.in_bundle?
  require 'bundler'
  if STDOUT.tty?
    begin
      Bundler.setup
    rescue Bundler::BundlerError => e
      puts "\e[31m#{e.message}\e[0m"
      puts e.backtrace.join("\n") if ENV["DEBUG"]
      if Bundler::GemNotFound === e
        puts "\e[33mRun `bundle install` to install missing gems.\e[0m"
      end
      exit e.status_code
    end
  elsif ENV['BUNDLE_EXECING']
    require 'bundler/vendored_thor'
    the_shell = (ENV['BUNDLE_EXECING'] == "no-color" ? Thor::Shell::Basic.new : Thor::Base.shell.new)
    Bundler.ui = Bundler::UI::Shell.new(the_shell)
    Bundler.with_friendly_errors {Bundler.setup }
  else
    Bundler.setup
  end

  # Add bundler to the load path after disabling system gems
  bundler_lib = File.expand_path("../..", __FILE__)
  $LOAD_PATH.unshift(bundler_lib) unless $LOAD_PATH.include?(bundler_lib)
end
