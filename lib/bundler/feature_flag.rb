# frozen_string_literal: true
module Bundler
  class FeatureFlag
    def self.settings_flag(flag)
      unless Bundler::Settings::BOOL_KEYS.include?(flag.to_s)
        raise "Cannot use `#{flag}` as a settings feature flag since it isn't a bool key"
      end
      define_method("#{flag}?") { Bundler.settings[flag] }
    end

    (1..10).each {|v| define_method("bundler_#{v}_mode?") { major_version >= v } }

    settings_flag :allow_offline_install
    settings_flag :plugins

    def initialize(bundler_version)
      @bundler_version = Gem::Version.create(bundler_version)
    end

    def major_version
      @bundler_version.segments.first
    end
    private :major_version

    class << self; private :settings_flag; end
  end
end
