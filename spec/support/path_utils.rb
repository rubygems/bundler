module Spec
  module PathUtils
    def root
      Pathname.new(__FILE__).dirname.join('..', '..').expand_path
    end

    def tmp_path(*path)
      root.join("tmp", *path).expand_path
    end

    # def tmp_dir
    #   this_file.join("..", "tmp")
    # end

    def bundled_app(*path)
      tmp_path.join("bundled_app").join(*path)
    end

    def tmp_gem_path(*path)
      bundled_app("vendor", "gems").join(*path)
    end

    def tmp_bindir(*path)
      bundled_app("bin").join(*path)
    end

    # def tmp_file(*path)
    #   tmp_dir.join(*path)
    # end

    def cache_path(*path)
      bundled_app.join("cache", *path)
    end

    def cached(gem_name)
      cache_path.join("#{gem_name}.gem")
    end

    def fixture_dir
      root.join("spec", "fixtures")
    end

    def gem_repo1(*path)
      fixture_dir.join("repository1", *path).expand_path
    end

    def gem_repo2(*path)
      fixture_dir.join("repository2", *path).expand_path
    end

    def gem_repo3(*path)
      fixture_dir.join("repository3", *path).expand_path
    end

    def fixture(gem_name)
      fixture_dir.join("repository1", "gems", "#{gem_name}.gem")
    end

    def system_gem_path(*path)
      tmp_path('system_gems', *path)
    end

    def copy(gem_name)
      FileUtils.cp(fixture(gem_name), File.join(tmp_dir, 'cache'))
    end
  end
end