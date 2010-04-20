module Spec
  module Platforms
    def rb
      %|Gem::Platform::RUBY|
    end

    def java
      %|Gem::Platform.new([nil, "java", nil])|
    end

    def linux
      %|Gem::Platform.new(['x86', 'linux', nil])|
    end

    def mswin
      %|Gem::Platform.new(['x86', 'mswin32', nil])|
    end
  end
end