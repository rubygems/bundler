# frozen_string_literal: true

module Bundler
  # This is the interfacing class represents the API that we intend to provide
  # the plugins to use.
  #
  # For plugins to be independent of the Bundler internals they shall limit their
  # interactions to methods of this class only. This will save them from breaking
  # when some internal change.
  #
  # Currently we are delegating the methods defined in Bundler class to
  # itself. So, this class acts as a buffer.
  #
  # If there is some change in the Bundler class that is incompatible to its
  # previous behavior or if otherwise desired, we can reimplement(or implement)
  # the method to preserve compatibility.
  #
  # To use this, either the class can inherit this class or use it directly.
  # For example of both types of use, refer the file `spec/plugins/command.rb`
  #
  # To use it without inheriting, you will have to create an object of this
  # to use the functions (except for declaration functions like command, source,
  # and hooks).
  module Plugin
    class API
      # The plugins should declare that they handle a command through this helper.
      #
      # @param [String] command being handled by them
      # @param [Class] (optional) class that shall handle the command. If not
      #                 provided, the `self` class will be used.
      def self.command(command, cls = self)
        Plugin.add_command command, cls
      end

      # The cache dir to be used by the plugins for persistance storage
      #
      # @return [Pathname] path of the cache dir
      def cache
        Plugin.cache.join("plugins")
      end

      # A tmp dir to be used by plugins
      #
      # @param [String] name unique for the plugin or the purpose
      # @return [Pathname] object for the new directory created
      def tmp(name)
        Bundler.tmp(File.join(["plugin", name]))
      end

      def method_missing(name, *args, &blk)
        super unless Bundler.respond_to?(name)
        Bundler.send(name, *args, &blk)
      end
    end
  end
end
