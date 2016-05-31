# frozen_string_literal: true

module Bundler
  # This is the interfacing class represents the API that we intend to provide
  # the plugins to use.
  #
  # For plugins to be independent of the Bundler internals they shall limit their
  # interactions to methods of this class only. This will save them from breaking
  # when some internal change.
  class Plugin::Api
    def self.command(command)
      Plugin.add_command command, self
    end

    # The cache dir to be used by the plugins for persistance storage
    #
    # @return [Pathname] path of the cache dir
    def cache
      Plugin.cache.join("plugins")
    end

    # A tmp dir to be used by plugins
    # Note: Its desirable to explicitly remove the dir after use
    #
    # @param [String] name unique for the plugin or the purpose
    # @return [Pathname] object for the new directory created
    def tmp(name)
      Bundler.tmp(File.join(["plugin", name]))
    end
  end
end
