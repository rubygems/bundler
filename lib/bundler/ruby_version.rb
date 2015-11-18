module Bundler
  class RubyVersion
    attr_reader :version, :patchlevel, :engine, :engine_version

    def initialize(version, patchlevel, engine, engine_version)
      # The parameters to this method must satisfy the
      # following constraints, which are verified in
      # the DSL:
      #
      # * If an engine is specified, an engine version
      #   must also be specified
      # * If an engine version is specified, an engine
      #   must also be specified
      # * If the engine is "ruby", the engine version
      #   must not be specified, or the engine version
      #   specified must match the version.

      @version        = version
      @engine         = engine || "ruby"
      # keep track of the engine specified by the user
      @input_engine   = engine
      @engine_version = engine_version || version
      @patchlevel     = patchlevel
    end

    def to_s
      output = "ruby #{version}"
      output << "p#{patchlevel}" if patchlevel
      output << " (#{engine} #{engine_version})" unless engine == "ruby"

      output
    end

    def ==(other)
      version == other.version &&
        engine == other.engine &&
        engine_version == other.engine_version &&
        patchlevel == other.patchlevel
    end

    def host
      @host ||= [
        RbConfig::CONFIG["host_cpu"],
        RbConfig::CONFIG["host_vendor"],
        RbConfig::CONFIG["host_os"]
      ].join("-")
    end

    def gem_version
      Gem::Version.new(version)
    end
  end

  # A subclass of RubyVersion that implements version,
  # engine and engine_version based upon the current
  # information in the system. It can be used anywhere
  # a RubyVersion object is expected, and can be
  # compared with a RubyVersion object.
  class SystemRubyVersion < RubyVersion
    def initialize(*)
      # override the default initialize, because
      # we will implement version, engine and
      # engine_version dynamically
    end

    def version
      RUBY_VERSION.dup
    end

    def gem_version
      @gem_version ||= Gem::Version.new(version)
    end

    def engine
      if defined?(RUBY_ENGINE)
        RUBY_ENGINE.dup
      else
        # not defined in ruby 1.8.7
        "ruby"
      end
    end

    def engine_version
      case engine
      when "ruby"
        RUBY_VERSION.dup
      when "rbx"
        Rubinius::VERSION.dup
      when "jruby"
        JRUBY_VERSION.dup
      else
        raise BundlerError, "RUBY_ENGINE value #{RUBY_ENGINE} is not recognized"
      end
    end

    def patchlevel
      RUBY_PATCHLEVEL.to_s
    end
  end

  class RubyVersionRequirement
    def initialize(version, patchlevel, engine, engine_version)
      @ruby_version = RubyVersion.new version, patchlevel, engine, engine_version
    end

    # Returns a tuple of these things:
    #   [diff, this, other]
    #   The priority of attributes are
    #   1. engine
    #   2. ruby_version
    #   3. engine_version
    def diff(other)
      if engine != other.engine && input_engine
        [:engine, engine, other.engine]
      elsif !version || !matches?(version, other.version)
        [:version, version, other.version]
      elsif input_engine && !matches?(engine_version, other.engine_version)
        [:engine_version, engine_version, other.engine_version]
      elsif patchlevel && !matches?(patchlevel, other.patchlevel)
        [:patchlevel, patchlevel, other.patchlevel]
      else
        nil
      end
    end

    def gem_version
      @ruby_version.gem_version
    end

    def ==(other)
      version == other.version &&
        engine == other.engine &&
        engine_version == other.engine_version &&
        patchlevel == other.patchlevel
    end

    def input_engine
      @ruby_version.instance_variable_get(:@input_engine)
    end

    def engine
      @ruby_version.engine
    end

    def patchlevel
      @ruby_version.patchlevel
    end

    def engine_version
      @ruby_version.engine_version
    end

    def version
      @ruby_version.version
    end

    def to_s
      @ruby_version.to_s
    end

    private

    def matches?(requirement, version)
      Gem::Requirement.create(requirement).satisfied_by?(Gem::Version.new(version))
    end
  end
end
