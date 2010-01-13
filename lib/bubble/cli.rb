$:.unshift File.expand_path('../vendor', __FILE__)
require 'thor'
require 'bubble'
require 'rubygems/config_file'

# Work around a RubyGems bug
Gem.configuration

module Bubble
  class CLI < Thor
    desc "init", "Generates a Gemfile into the current working directory"
    def init
      if File.exist?("Gemfile")
        puts "Gemfile already exists at `#{Dir.pwd}/Gemfile`"
      else
        puts "Writing new Gemfile to `#{Dir.pwd}/Gemfile`"
        FileUtils.cp(File.expand_path('../templates/Gemfile', __FILE__), 'Gemfile')
      end
    end

    desc "install", "Install the current environment to the system"
    def install
      Installer.install(Bubble.definition)
    end
  end
end