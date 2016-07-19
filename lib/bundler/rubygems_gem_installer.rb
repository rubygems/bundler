# frozen_string_literal: true
require "rubygems/installer"

module Bundler
  class RubyGemsGemInstaller < Gem::Installer
    unless respond_to?(:at)
      def self.at(*args)
        new(*args)
      end
    end

    def check_executable_overwrite(filename)
      # Bundler needs to install gems regardless of binstub overwriting
    end
  end
end
