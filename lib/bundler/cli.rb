module Bundler
  module CLI

    module_function

    def default_manifest
      current = Pathname.new(Dir.pwd)

      begin
        manifest = current.join("Gemfile")
        return manifest.to_s if File.exist?(manifest)
        current = current.parent
      end until current.root?
      nil
    end

    def default_path
      return unless default_manifest
      Pathname.new(File.dirname(default_manifest)).join("vendor").join("gems").to_s
    end

    def default_bindir
      return unless default_manifest
      Pathname.new(File.dirname(default_manifest)).join("bin").to_s
    end

  end
end