module Spec
  module PathUtils
    def root
      @root ||= Pathname.new(__FILE__).dirname.join('..', '..').expand_path
    end

    def tmp_path(*path)
      root.join("tmp", *path).expand_path
    end

    alias fixture_dir tmp_path

    def bundled_app(*path)
      tmp_path.join("bundled_app").join(*path)
    end

    def bundled_path
      @bundled_path ||= bundled_app("vendor/gems/#{Gem.ruby_engine}/#{Gem::ConfigMap[:ruby_version]}")
    end

    def tmp_gem_path(*path)
      bundled_path.join(*path)
    end

    def tmp_bindir(*path)
      bundled_app("bin").join(*path)
    end

    def cache_path(*path)
      bundled_app.join("cache", *path)
    end

    def cached(gem_name)
      cache_path.join("#{gem_name}.gem")
    end

    def gem_repo1(*path)
      tmp_path("repos/1")
    end

    def gem_repo2(*path)
      tmp_path("repos/2")
    end

    def gem_repo2(*path)
      tmp_path("repos/3")
    end

    def system_gem_path(*path)
      tmp_path('system_gems', *path)
    end

    def copy(gem_name)
      FileUtils.cp(fixture(gem_name), File.join(tmp_dir, 'cache'))
    end

    def app_root
      Dir.chdir bundled_app do
        yield
      end
    end
  end
end
