module Spec
  module PathUtils
    def this_file
      Pathname.new(__FILE__).dirname.join('..').expand_path
    end

    def tmp_dir
      this_file.join("..", "tmp")
    end

    def tmp_gem_path(*path)
      tmp_file("vendor", "gems").join(*path)
    end

    def tmp_bindir(*path)
      tmp_file("bin").join(*path)
    end

    def tmp_file(*path)
      tmp_dir.join(*path)
    end

    def cached(gem_name)
      File.join(tmp_dir, 'cache', "#{gem_name}.gem")
    end

    def fixture_dir
      this_file.join("fixtures")
    end

    def gem_repo1
      fixture_dir.join("repository1").expand_path
    end

    def gem_repo2
      fixture_dir.join("repository2").expand_path
    end

    def gem_repo3
      fixture_dir.join("repository3").expand_path
    end

    def fixture(gem_name)
      fixture_dir.join("repository1", "gems", "#{gem_name}.gem")
    end

    def copy(gem_name)
      FileUtils.cp(fixture(gem_name), File.join(tmp_dir, 'cache'))
    end
  end
end