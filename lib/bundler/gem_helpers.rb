# frozen_string_literal: true
module Bundler
  module GemHelpers
    GENERIC_CACHE = {} # rubocop:disable MutableConstant
    GENERICS = [
      [Gem::Platform.new("java"), Gem::Platform.new("java")],
      [Gem::Platform.new("mswin32"), Gem::Platform.new("mswin32")],
      [Gem::Platform.new("mswin64"), Gem::Platform.new("mswin64")],
      [Gem::Platform.new("universal-mingw32"), Gem::Platform.new("universal-mingw32")],
      [Gem::Platform.new("x64-mingw32"), Gem::Platform.new("x64-mingw32")],
      [Gem::Platform.new("x86_64-mingw32"), Gem::Platform.new("x64-mingw32")],
      [Gem::Platform.new("mingw32"), Gem::Platform.new("x86-mingw32")]
    ].freeze

    def generic(p)
      return p if p == Gem::Platform::RUBY

      GENERIC_CACHE[p] ||= begin
        _, found = GENERICS.find do |match, _generic|
          p.os == match.os && (!match.cpu || p.cpu == match.cpu)
        end
        found || Gem::Platform::RUBY
      end
    end
    module_function :generic

    def generic_local_platform
      generic(Gem::Platform.local)
    end
    module_function :generic_local_platform

    def platform_specificity_match(spec_platform, user_platform)
      spec_platform = Gem::Platform.new(spec_platform)
      return [-1, -1, -1] if spec_platform == user_platform
      return [5, 5, 5] if spec_platform.nil? || spec_platform == Gem::Platform::RUBY || user_platform == Gem::Platform::RUBY

      [
        if spec_platform.os == user_platform.os
          0
        else
          1
        end,

        if spec_platform.cpu == user_platform.cpu
          0
        elsif spec_platform.cpu == "arm" && user_platform.cpu.to_s.start_with?("arm")
          0
        elsif spec_platform.cpu.nil? || spec_platform.cpu == "universal"
          1
        else
          2
        end,

        if spec_platform.version == user_platform.version
          0
        elsif spec_platform.version.nil?
          1
        else
          2
        end,
      ]
    end
    module_function :platform_specificity_match
  end
end
