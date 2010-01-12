$:.unshift File.expand_path('../vendor', __FILE__)
require 'thor'
require 'bubble'
require 'rubygems/config_file'

# Work around a RubyGems bug
Gem.configuration

module Bubble
  class CLI < Thor
    desc "install", "Install the current environment to the system"
    def install
      Installer.install(Bubble.definition)
    end
  end
end