# frozen_string_literal: true
require "bundler/vendored_thor"
module Bundler
  class CLI::Plugin < Thor

    desc "install PLUGIN", "Install the plugin from the source"
    long_desc <<-D
      Install a plugin named PLUGIN wither from the rubygems source provided (with --source option) or from a git source provided with (--git option).
    D
    method_option "source", :type=> :string, :default => nil, :banner =>
      "Url of the RubyGems source to fetch the plugin from"
    method_option "version", :type=> :string, :default => nil, :banner =>
      "The version of the plugin to fetch from"
    def install(plugin)
      Bundler::Plugin.install(plugin, options)
    end
  end
end
