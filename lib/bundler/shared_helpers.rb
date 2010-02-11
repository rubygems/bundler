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

  end
end