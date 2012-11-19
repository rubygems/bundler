module Bundler

  if defined? ::Deprecate
    Deprecate = ::Deprecate
  elsif defined? Gem::Deprecate
    Deprecate = Gem::Deprecate
  end
  
  unless defined?(Deprecate) && Deprecate.respond_to?(:skip_during)
    class Deprecate
      def skip_during; yield; end
    end
  end

end