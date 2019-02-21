# frozen_string_literal: true

module Spec
  module SimpleCov
    def self.setup
      require "simplecov"
      configure_exclusions
    end

    def self.configure_exclusions
      SimpleCov.start do
        add_filter "/bin/"
        add_filter "/lib/bundler/man/"
        add_filter "/lib/bundler/vendor/"
        add_filter "/man/"
        add_filter "/pkg/"
        add_filter "/spec/"
        add_filter "/tmp/"
      end
    end
  end
end
