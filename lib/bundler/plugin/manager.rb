require "yaml"
require "fileutils"

module Bundler
  module Plugin
    # The Manager helps with installing, listing, and initializing user level plugins.
    class Manager
      def initialize
        @path = Bundler.user_bundle_path.join("plugins.yml")
        dirname = File.dirname(@path)
        unless File.directory?(dirname)
          FileUtils.mkdir_p(dirname)
        end
        begin
          @data = YAML.load_file(@path)
        rescue => e
          @data = []
        end
      end

      def self.instance
        @instance ||= self.new
      end

      def installed_plugins
        @data
      end

      def install_plugin(name)
        @data.push(name)
        save!
      end

      def uninstall_plugin(name)
        @data.delete(name)
        save!
      end

      def save!
        File.open(@path,"w+") do |f|
          f.write(YAML.dump(@data))
        end
      end
    end
  end
end
