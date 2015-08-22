require 'bundler/setup'

# cache rack -> /foo/bar/vendor/bundle/rack/lib/rack.rb
module Bundler
  PRELOADED_REQUIRE = {}
  $LOAD_PATH.reverse_each do |path|
    Dir["#{path}/**/*.rb"].each do |f|
      start = path.size + 1
      count = f.size - start - 3 # without '.rb' = last 3
      PRELOADED_REQUIRE[f.slice(start, count)] = f
    end
  end
  PRELOADED_REQUIRE[:state] = $LOAD_PATH.join('')

  # Bundler::StaticSetup.verification = :warn
  module StaticSetup
    class << self
      attr_accessor :verification
    end
  end
end

module Kernel
  alias require_without_bundler_preload require
  def require(path)
    verification = ::Bundler::StaticSetup.verification
    if !verification.nil? && ::Bundler::PRELOADED_REQUIRE.fetch(:state) != $LOAD_PATH.join('')
      case verification
      when :warn then warn "$LOAD_PATH was changed"
      when :raise then raise "$LOAD_PATH was changed"
      when :skip then require_without_bundler_preload(path)
      else
        raise ::ArgumentError, "Unknown verification option #{verification}"
      end
    end

    if f = ::Bundler::PRELOADED_REQUIRE[path]
      require_without_bundler_preload(f)
    else
      require_without_bundler_preload(path)
    end
  end
end
