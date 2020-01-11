# frozen_string_literal: true

require_relative "path"

module Spec
  module Rubygems
    DEV_DEPS = {
      "automatiek" => "~> 0.3.0",
      "parallel_tests" => "~> 2.29",
      "rake" => "~> 12.0",
      "ronn" => "~> 0.7.3",
      "rspec" => "~> 3.8",
      "rubocop" => "= 0.77.0",
      "rubocop-performance" => "= 1.5.1",
    }.freeze

    DEPS = {
      "rack" => "2.0.8",
      "rack-test" => "~> 1.1",
      "artifice" => "~> 0.6.0",
      "compact_index" => "~> 0.11.0",
      "sinatra" => "~> 2.0",
      # Rake version has to be consistent for tests to pass
      "rake" => "12.3.2",
      "builder" => "~> 3.2",
      # ruby-graphviz is used by the viz tests
      "ruby-graphviz" => ">= 0.a",
    }.freeze

    extend self

    def dev_setup
      deps = DEV_DEPS

      # JRuby can't build ronn, so we skip that
      deps.delete("ronn") if RUBY_ENGINE == "jruby"

      install_gems(deps)
    end

    def gem_load(gem_name, bin_container)
      require_relative "rubygems_version_manager"
      RubygemsVersionManager.new(ENV["RGV"]).switch

      gem_load_and_activate(gem_name, bin_container)
    end

    def gem_require(gem_name)
      gem_activate(gem_name)
      require gem_name
    end

    def setup
      install_test_deps

      require "fileutils"

      FileUtils.mkdir_p(Path.home)
      FileUtils.mkdir_p(Path.tmpdir)

      ENV["HOME"] = Path.home.to_s
      ENV["TMPDIR"] = Path.tmpdir.to_s

      require "rubygems/user_interaction"
      Gem::DefaultUserInteraction.ui = Gem::SilentUI.new
    end

    def install_parallel_test_deps
      require "parallel"

      prev_env_test_number = ENV["TEST_ENV_NUMBER"]

      begin
        Parallel.processor_count.times do |n|
          ENV["TEST_ENV_NUMBER"] = (n + 1).to_s

          install_test_deps
        end
      ensure
        ENV["TEST_ENV_NUMBER"] = prev_env_test_number
      end
    end

    def install_test_deps
      Gem.clear_paths

      ENV["BUNDLE_PATH"] = nil
      ENV["GEM_HOME"] = ENV["GEM_PATH"] = Path.base_system_gems.to_s
      ENV["PATH"] = [Path.bindir, Path.system_gem_path.join("bin"), ENV["PATH"]].join(File::PATH_SEPARATOR)

      install_gems(DEPS)
    end

  private

    def gem_load_and_activate(gem_name, bin_container)
      gem_activate(gem_name)
      load Gem.bin_path(gem_name, bin_container)
    rescue Gem::LoadError => e
      abort "We couln't activate #{gem_name} (#{e.requirement}). Run `gem install #{gem_name}:'#{e.requirement}'`"
    end

    def gem_activate(gem_name)
      gem_requirement = DEV_DEPS[gem_name]
      gem gem_name, gem_requirement
    end

    def install_gems(gems)
      deps = gems.map {|name, req| "'#{name}:#{req}'" }.join(" ")
      gem = ENV["GEM_COMMAND"] || "#{Gem.ruby} -S gem --backtrace"
      cmd = "#{gem} install #{deps} --no-document --conservative"
      system(cmd) || raise("Installing gems #{deps} for the tests to use failed!")
    end
  end
end
