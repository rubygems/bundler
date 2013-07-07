require 'rubygems/dependency'
require 'bundler/shared_helpers'
require 'bundler/rubygems_ext'

module Bundler
  class Dependency < Gem::Dependency
    attr_reader :autorequire
    attr_reader :groups
    attr_reader :platforms

    PLATFORM_MAP = {
      :ruby     => Gem::Platform::RUBY,
      :ruby_18  => Gem::Platform::RUBY,
      :ruby_19  => Gem::Platform::RUBY,
      :ruby_20  => Gem::Platform::RUBY,
      :mri      => Gem::Platform::RUBY,
      :mri_18   => Gem::Platform::RUBY,
      :mri_19   => Gem::Platform::RUBY,
      :mri_20   => Gem::Platform::RUBY,
      :rbx      => Gem::Platform::RUBY,
      :jruby    => Gem::Platform::JAVA,
      :mswin    => Gem::Platform::MSWIN,
      :mingw    => Gem::Platform::MINGW,
      :mingw_18 => Gem::Platform::MINGW,
      :mingw_19 => Gem::Platform::MINGW,
      :mingw_20 => Gem::Platform::MINGW,
      :ruboto   => Gem::Platform::DALVIK,
      :ruboto_1 => Gem::Platform::DALVIK,
      :ruboto_2 => Gem::Platform::DALVIK,
      :ruboto_3 => Gem::Platform::DALVIK,
      :ruboto_4 => Gem::Platform::DALVIK,
      :ruboto_5 => Gem::Platform::DALVIK,
      :ruboto_6 => Gem::Platform::DALVIK,
      :ruboto_7 => Gem::Platform::DALVIK,
      :ruboto_8 => Gem::Platform::DALVIK,
      :ruboto_9 => Gem::Platform::DALVIK,
      :ruboto_10 => Gem::Platform::DALVIK,
      :ruboto_11 => Gem::Platform::DALVIK,
      :ruboto_12 => Gem::Platform::DALVIK,
      :ruboto_13 => Gem::Platform::DALVIK,
      :ruboto_14 => Gem::Platform::DALVIK,
      :ruboto_15 => Gem::Platform::DALVIK,
      :ruboto_16 => Gem::Platform::DALVIK,
      :ruboto_17 => Gem::Platform::DALVIK
    }.freeze

    DALVIK_PLATFORM_MAP = {
      :ruboto   => Gem::Platform::DALVIK,
      :ruboto_1 => Gem::Platform.new('dalvik1'),
      :ruboto_2 => Gem::Platform.new('dalvik2'),
      :ruboto_3 => Gem::Platform.new('dalvik3'),
      :ruboto_4 => Gem::Platform.new('dalvik4'),
      :ruboto_5 => Gem::Platform.new('dalvik5'),
      :ruboto_6 => Gem::Platform.new('dalvik6'),
      :ruboto_7 => Gem::Platform.new('dalvik7'),
      :ruboto_8 => Gem::Platform.new('dalvik8'),
      :ruboto_9 => Gem::Platform.new('dalvik9'),
      :ruboto_10 => Gem::Platform.new('dalvik10'),
      :ruboto_11 => Gem::Platform.new('dalvik11'),
      :ruboto_12 => Gem::Platform.new('dalvik12'),
      :ruboto_13 => Gem::Platform.new('dalvik13'),
      :ruboto_14 => Gem::Platform.new('dalvik14'),
      :ruboto_15 => Gem::Platform.new('dalvik15'),
      :ruboto_16 => Gem::Platform.new('dalvik16'),
      :ruboto_17 => Gem::Platform.new('dalvik17')
    }.freeze

    def initialize(name, version, options = {}, &blk)
      type = options["type"] || :runtime
      super(name, version, type)

      @autorequire = nil
      @groups      = Array(options["group"] || :default).map { |g| g.to_sym }
      @source      = options["source"]
      @platforms   = Array(options["platforms"])
      @env         = options["env"]

      if options.key?('require')
        @autorequire = Array(options['require'] || [])
      end
    end

    def self.gem_platform(platform)
      PLATFORM_MAP[platform]
    end

    def self.dalvik_platform(platform)
      DALVIK_PLATFORM_MAP[platform]
    end

    def gem_platforms(valid_platforms)
      return valid_platforms if @platforms.empty?

      platforms = []
      @platforms.each do |p|
        platform = PLATFORM_MAP[p]
        next unless valid_platforms.include?(platform)
        platforms |= [platform]
      end
      platforms
    end

    def should_include?
      current_env? && current_platform?
    end

    def current_env?
      return true unless @env
      if Hash === @env
        @env.all? do |key, val|
          ENV[key.to_s] && (String === val ? ENV[key.to_s] == val : ENV[key.to_s] =~ val)
        end
      else
        ENV[@env.to_s]
      end
    end

    def current_platform?
      return true if @platforms.empty?
      if Bundler.settings[:platform]
        current = Dependency.gem_platform(Bundler.settings[:platform].to_sym)
        return @platforms.any? { |p| p == current }
      end
      @platforms.any? { |p| send("#{p}?") }
    end

    def to_lock
      out = super
      out << '!' if source
      out << "\n"
    end


    def specific?
      super
    rescue NoMethodError
      requirement != ">= 0"
    end

  private

    def on_18?
      RUBY_VERSION =~ /^1\.8/
    end

    def on_19?
      RUBY_VERSION =~ /^1\.9/
    end

    def on_20?
      RUBY_VERSION =~ /^2\.0/
    end

    def ruby?
      !mswin? && (!defined?(RUBY_ENGINE) || RUBY_ENGINE == "ruby" || RUBY_ENGINE == "rbx" || RUBY_ENGINE == "maglev")
    end

    def ruby_18?
      ruby? && on_18?
    end

    def ruby_19?
      ruby? && on_19?
    end

    def ruby_20?
      ruby? && on_20?
    end

    def mri?
      !mswin? && (!defined?(RUBY_ENGINE) || RUBY_ENGINE == "ruby")
    end

    def mri_18?
      mri? && on_18?
    end

    def mri_19?
      mri? && on_19?
    end


    def mri_20?
      mri? && on_20?
    end

    def rbx?
      ruby? && defined?(RUBY_ENGINE) && RUBY_ENGINE == "rbx"
    end

    def jruby?
      defined?(RUBY_ENGINE) && RUBY_ENGINE == "jruby"
    end

    def maglev?
      defined?(RUBY_ENGINE) && RUBY_ENGINE == "maglev"
    end

    def mswin?
      Bundler::WINDOWS
    end

    def mingw?
      Bundler::WINDOWS && Gem::Platform.local.os == "mingw32"
    end

    def mingw_18?
      mingw? && on_18?
    end

    def mingw_19?
      mingw? && on_19?
    end

    def mingw_20?
      mingw? && on_20?
    end

  end
end
