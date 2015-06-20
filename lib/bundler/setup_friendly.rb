require 'bundler/shared_helpers'

module Bundler
  def self.setup_friendly *groups
    if SharedHelpers.in_bundle?
      require 'bundler'
      require_relative 'friendly_errors'
      require 'bundler/ui/shell'
      require 'bundler/ui/silent'

      Bundler.ui = if STDOUT.tty? || ENV['BUNDLER_FORCE_TTY']
        Bundler::UI::Shell.new
      else
        Bundler::UI::Silent.new
      end

      Bundler.with_friendly_errors do
        if groups.empty?
          Bundler.setup
        else
          Bundler.setup groups
        end
      end

      # Add bundler to the load path after disabling system gems
      bundler_lib = File.expand_path("../..", __FILE__)
      $LOAD_PATH.unshift(bundler_lib) unless $LOAD_PATH.include?(bundler_lib)

      Bundler.ui = nil
    end
  end
end
