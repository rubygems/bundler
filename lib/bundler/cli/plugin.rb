# frozen_string_literal: true
require "bundler/vendored_thor"
module Bundler
  class CLI::Plugin < Thor
    desc "install PLUGIN ", "Install the plugin"
    method_option "git", :type => :string, :default => false, :banner =>
      "The git repo to install the plugin from"
    def install(plugin)
      unless options[:git]
        puts <<-W
          Only git modules are supported as of now
          Pass the git path with --git option
        W
        return
      end

      Bundler::Plugin.install(plugin, options[:git])
    end
  end
end
