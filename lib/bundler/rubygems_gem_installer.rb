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

    def pre_install_checks
      super && validate_bundler_checksum(options[:bundler_expected_checksum])
    end

  private

    def validate_bundler_checksum(checksum)
      return true if Bundler.settings[:disable_checksum_validation]
      return true unless checksum
      return true unless source = @package.instance_variable_get(:@gem)
      return true unless source.respond_to?(:with_read_io)
      digest = source.with_read_io do |io|
        digest = Digest::SHA256.new
        digest << io.read(16_384) until io.eof?
        io.rewind
        digest.send(checksum_type(checksum))
      end
      unless digest == checksum
        raise SecurityError,
          "The checksum for the downloaded `#{spec.full_name}.gem` did not match " \
          "the checksum given by the API. This means that the contents of the " \
          "gem appear to be different from what was uploaded, and could be an indicator of a security issue.\n" \
          "(The expected SHA256 checksum was #{checksum.inspect}, but the checksum for the downloaded gem was #{digest.inspect}.)\n" \
          "Bundler cannot continue installing #{spec.name} (#{spec.version})."
      end
      true
    end

    def checksum_type(checksum)
      case checksum.length
      when 64 then :hexdigest!
      when 44 then :base64digest!
      else raise InstallError, "The given checksum for #{spec.full_name} (#{checksum.inspect}) is not a valid SHA256 hexdigest nor base64digest"
      end
    end
  end
end
