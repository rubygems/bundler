# frozen_string_literal: true
module Bundler
  class RubyVersion
    attr_reader :version, :patchlevel, :engine, :engine_version, :gem_version

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
      @gem_version    = Gem::Requirement.create(version).requirements.first.last
      @input_engine   = engine
      @engine         = engine || "ruby"
      @engine_version = engine_version || version
      @patchlevel     = patchlevel
    end

    def to_s
      output = String.new("ruby #{version}")
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

    # Returns a tuple of these things:
    #   [diff, this, other]
    #   The priority of attributes are
    #   1. engine
    #   2. ruby_version
    #   3. engine_version
    def diff(other)
      if engine != other.engine && @input_engine
        [:engine, engine, other.engine]
      elsif !version || !matches?(version, other.version)
        [:version, version, other.version]
      elsif @input_engine && !matches?(engine_version, other.engine_version)
        [:engine_version, engine_version, other.engine_version]
      elsif patchlevel && (!patchlevel.is_a?(String) || !other.patchlevel.is_a?(String) || !matches?(patchlevel, other.patchlevel))
        [:patchlevel, patchlevel, other.patchlevel]
      end
    end

    def self.system
      ruby_engine = if defined?(RUBY_ENGINE) && !RUBY_ENGINE.nil?
        RUBY_ENGINE.dup
      else
        # not defined in ruby 1.8.7
        "ruby"
      end
      ruby_engine_version = case ruby_engine
                            when "ruby"
                              RUBY_VERSION.dup
                            when "rbx"
                              Rubinius::VERSION.dup
                            when "jruby"
                              JRUBY_VERSION.dup
                            else
                              raise BundlerError, "RUBY_ENGINE value #{RUBY_ENGINE} is not recognized"
      end
      @ruby_version ||= RubyVersion.new(RUBY_VERSION.dup, RUBY_PATCHLEVEL.to_s, ruby_engine, ruby_engine_version)
    end

  private

    def matches?(requirement, version)
      Gem::Requirement.create(requirement).satisfied_by?(Gem::Version.new(version))
    end
  end
end
