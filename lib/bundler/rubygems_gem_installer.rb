# frozen_string_literal: true
require "rubygems/installer"

module Bundler
  class RubyGemsGemInstaller < Gem::Installer
    def self.at(path, options = {})
      security_policy = options[:security_policy]
      package = Gem::Package.new path, security_policy
      new package, options
    end

    def check_executable_overwrite(filename)
      # Bundler needs to install gems regardless of binstub overwriting
    end
  end
end
