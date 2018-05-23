# frozen_string_literal: true

module Bundler
  module Plugin
    module Events
      def self.define(const, event)
        const_set(const.to_sym, event) unless const_defined?(const.to_sym)
        @events ||= {}
        @events[event] = const
      end

      def self.defined_event?(event)
        @events ||= {}
        @events.key?(event)
      end

      # A hook called before any gems install
      define :GEM_BEFORE_INSTALL_ALL, "before-install-all"
    end
  end
end
