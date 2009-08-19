$:.unshift File.expand_path(File.join(File.dirname(__FILE__)))
$:.unshift File.expand_path(File.join(File.dirname(__FILE__), '..', 'lib'))
require "rubygems"
require "bundler"

require "spec"
require "matchers"
require "builders"
require "rbconfig"

class Pathname
  def mkdir_p
    FileUtils.mkdir_p(self)
  end

  def touch_p
    dirname.mkdir_p
    touch
  end

  def touch
    FileUtils.touch(self)
  end
end

module Spec
  module Helpers
    def this_file
      Pathname.new(File.expand_path(File.dirname(__FILE__)))
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

    def run_in_context(*args)
      cmd = args.pop.gsub(/(?=")/, "\\")
      env = args.pop || tmp_file("vendor", "gems", "environment")
      lib = File.join(File.dirname(__FILE__), '..', 'lib')
      %x{#{Gem.ruby} -I#{lib} -r #{env} -e "#{cmd}"}.strip
    end

    def gem_command(command, args = "")
      if command == :exec
        args = args.gsub(/(?=")/, "\\")
        args = %["#{args}"]
      end
      lib  = File.join(File.dirname(__FILE__), '..', 'lib')
      %x{#{Gem.ruby} -I#{lib} -rubygems -S gem #{command} #{args}}.strip
    end

    def build_manifest_file(*args)
      path = tmp_file("Gemfile")
      path = args.shift if args.first.is_a?(Pathname)
      str  = args.shift || ""
      FileUtils.mkdir_p(path.dirname)
      File.open(path, 'w') do |f|
        f.puts str
      end
    end

    def build_manifest(*args)
      path = tmp_file("Gemfile")
      path = args.shift if args.first.is_a?(Pathname)
      str  = args.shift || ""
      FileUtils.mkdir_p(path.dirname)
      Dir.chdir(path.dirname) do
        build_manifest_file(path, str)
        Bundler::ManifestFile.load(path)
      end
    end

    def install_manifest(*args)
      m = build_manifest(*args)
      m.install
      m
    end

    def reset!
      tmp_dir.rmtree if tmp_dir.exist?
      tmp_dir.mkdir
    end
  end
end

Spec::Runner.configure do |config|
  config.include Spec::Builders
  config.include Spec::Matchers
  config.include Spec::Helpers

  original_wd = Dir.pwd

  config.before(:each) do
    @log_output = StringIO.new
    Bundler.logger.instance_variable_set("@logdev", Logger::LogDevice.new(@log_output))
    reset!
  end

  config.after(:each) do
    Dir.chdir(original_wd)
  end
end
