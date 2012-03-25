module Bundler
  class RubyVersion
    attr_reader :version, :engine, :engine_version

    def initialize(version, engine, engine_version)
      @version        = version
      @engine         = engine || "ruby"
      @engine_version = @engine == "ruby" ? version : engine_version
    end

    def to_s
      "ruby #{@version} (#{@engine} #{@engine_version})"
    end
  end
end
