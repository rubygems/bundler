module Spec
  module Platforms
    include Bundler::GemHelpers

    def rb
      Gem::Platform::RUBY
    end

    def mac
      Gem::Platform.new('x86-darwin-10')
    end

    def java
      Gem::Platform.new([nil, "java", nil])
    end

    def linux
      Gem::Platform.new(['x86', 'linux', nil])
    end

    def mswin
      Gem::Platform.new(['x86', 'mswin32', nil])
    end

    def mingw
      Gem::Platform.new(['x86', 'mingw32', nil])
    end

    def all_platforms
      [rb, java, linux, mswin, mingw]
    end

    def local
      generic(Gem::Platform.local)
    end

    def not_local
      all_platforms.find { |p| p != generic(Gem::Platform.local) }
    end

    def local_tag
      if RUBY_PLATFORM == "java"
        :jruby
      else
        :ruby
      end
    end

    def not_local_tag
      [:ruby, :jruby].find { |tag| tag != local_tag }
    end
  end
end
