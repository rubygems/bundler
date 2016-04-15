# frozen_string_literal: true
module Bundler
  class EnvironmentPreserver
    # @param env [ENV]
    # @param keys [Array<String>]
    def initialize(env, keys)
      @original = env.to_hash
      @keys = keys
      @prefix = "BUNDLE_ORIG_"
    end

    # @return [Hash]
    def backup
      env = @original.clone
      @keys.each do |key|
        value = env[key]
        env[@prefix + key] = value unless value.nil? || value.empty?
      end
      env
    end

    # @return [Hash]
    def restore
      env = @original.clone
      @keys.each do |key|
        value_original = env[@prefix + key]
        unless value_original.nil? || value_original.empty?
          env[key] = value_original
          env.delete(@prefix + key)
        end
      end
      env
    end
  end
end
