# frozen_string_literal: true

module Bundler
  class Source
    class Metadata < Source
      def specs
        @specs ||= Index.build do |idx|
          idx << Gem::Specification.new("ruby\0", RubyVersion.system.to_gem_version_with_patchlevel)
          idx << Gem::Specification.new("rubygems\0", Gem::VERSION)
        end
      end

      def cached!; end

      def remote!; end

      def to_s
        "the local ruby installation"
      end

      def ==(other)
        self.class == other.class
      end
      alias_method :eql?, :==

      def hash
        self.class.hash
      end
    end
  end
end
