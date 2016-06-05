module BundlerVendoredPostIt
  class Installer
    def initialize(bundler_version)
      @bundler_version = bundler_version
    end

    def installed?
      !Gem::Specification.find_by_name('bundler', @bundler_version).nil?
    rescue Gem::MissingSpecVersionError
      false
    end

    def install!
      Gem.install('bundler', @bundler_version) unless installed?
    end
  end
end
