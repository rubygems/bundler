$:.unshift File.join(File.dirname(__FILE__), '..', 'lib')
$:.push File.join(File.dirname(__FILE__))
require "bundler"
require "bundler/resolver/builders"
require "matchers"
require "pathname"
require "pp"

module Spec
  module Helpers
    def this_file
      Pathname.new(File.expand_path(File.dirname(__FILE__)))
    end

    def tmp_dir
      this_file.join("fixtures", "tmp")
    end

    def tmp_file(*path)
      tmp_dir.join(*path)
    end

    def cached(gem_name)
      File.join(tmp_dir, 'cache', "#{gem_name}.gem")
    end

    def gem_repo1
      this_file.join("fixtures", "repository1").expand_path
    end

    def gem_repo2
      this_file.join("fixtures", "repository2").expand_path
    end

    def fixture(gem_name)
      this_file.join("fixtures", "repository1", "gems", "#{gem_name}.gem")
    end

    def copy(gem_name)
      FileUtils.cp(fixture(gem_name), File.join(tmp_dir, 'cache'))
    end
  end
end

Spec::Runner.configure do |config|
  config.include Bundler::Resolver::Builders
  config.include Spec::Matchers
  config.include Spec::Helpers
end