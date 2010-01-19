$:.unshift File.expand_path('../vendor', __FILE__)
require 'thor'
require 'bubble'
require 'rubygems/config_file'

# Work around a RubyGems bug
Gem.configuration

module Bubble
  class CLI < Thor
    def self.banner(task)
      task.formatted_usage(self, false)
    end

    desc "init", "Generates a Gemfile into the current working directory"
    def init
      if File.exist?("Gemfile")
        puts "Gemfile already exists at `#{Dir.pwd}/Gemfile`"
      else
        puts "Writing new Gemfile to `#{Dir.pwd}/Gemfile`"
        FileUtils.cp(File.expand_path('../templates/Gemfile', __FILE__), 'Gemfile')
      end
    end

    desc "check", "Checks if the dependencies listed in Gemfile are satisfied by currently installed gems"
    def check
      with_rescue do
        env = Bubble.load
        # Check top level dependencies
        missing = env.dependencies.select { |d| env.index.search(d).empty? }
        if missing.any?
          puts "The following dependencies are missing"
          missing.each do |d|
            puts "  * #{d}"
          end
        else
          env.specs
          puts "The Gemfile's dependencies are satisfied"
        end
      end
    rescue VersionConflict => e
      puts e.message
    end

    desc "install", "Install the current environment to the system"
    def install
      Installer.install(Bubble.definition)
    end

    desc "lock", "Locks a resolve"
    def lock
      Bubble.load.lock
    end

  private

    def with_rescue
      yield
    rescue GemfileNotFound => e
      puts e.message
      exit 1
    end
  end
end