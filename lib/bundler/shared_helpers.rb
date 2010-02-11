module Bundler
  module SharedHelpers

    def reverse_rubygems_kernel_mixin
      require "rubygems"

      # Disable rubygems' gem activation system
      ::Kernel.class_eval do
        if private_method_defined?(:gem_original_require)
          alias rubygems_require require
          alias require gem_original_require
        end

        undef gem
      end
    end

    def default_gemfile
      if ENV['BUNDLE_GEMFILE']
        return Pathname.new(ENV['BUNDLE_GEMFILE'])
      end

      current = Pathname.new(Dir.pwd)

      until current.root?
        filename = current.join("Gemfile")
        return filename if filename.exist?
        current = current.parent
      end

      raise GemfileNotFound, "The default Gemfile was not found"
    end

    def in_bundle?
      default_gemfile
    rescue GemfileNotFound
      false
    end

    extend self
  end
end