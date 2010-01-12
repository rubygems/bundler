module Spec
  module Path
    def root
      @root ||= Pathname.new(File.expand_path("../../..", __FILE__))
    end

    def tmp(*path)
      root.join("tmp", *path)
    end

    def home
      tmp.join("home")
    end

    def bundled_app(*path)
      tmp.join("bundled_app", *path)
    end

    def base_system_gems
      tmp.join("gems/base")
    end

    def gem_repo1
      tmp("gems/remote1")
    end

    def gem_repo2
      tmp("gems/remote2")
    end

    def system_gem_path
      tmp("gems/system")
    end

    extend self
  end
end