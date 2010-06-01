module Spec
  module Platforms
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

    def all_platforms
      [rb, java, linux, mswin]
    end

    def not_local
      all_platforms.reject { |p| p == Gem::Platform.local }
    end
  end
end