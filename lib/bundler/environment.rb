module Bundler
  class Environment
    def initialize(path)
      if !File.directory?(path)
        raise ArgumentError, "#{path} is not a directory"
      elsif !File.directory?(File.join(path, "cache"))
        raise ArgumentError, "#{path} is not a valid environment (it does not contain a cache directory)"
      end

      @path = path
    end
  end
end