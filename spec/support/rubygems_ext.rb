# frozen_string_literal: true
require "rubygems/user_interaction"
require "support/path" unless defined?(Spec::Path)

module Spec
  module Rubygems
    DEPS = begin
      deps = {
        # rack 2.x requires Ruby version >= 2.2.2.
        # artifice doesn't support rack 2.x now.
        "rack" => "< 2",
        "fakeweb artifice compact_index" => nil,
        "sinatra" => "1.2.7",
        # Rake version has to be consistent for tests to pass
        "rake" => "10.0.2",
        # 3.0.0 breaks 1.9.2 specs
        "builder" => "2.1.2",
        "bundler" => "1.12.0",
      }
      # ruby-graphviz is used by the viz tests
      deps["ruby-graphviz"] = nil if RUBY_VERSION >= "1.9.3"
      deps
    end

    def self.setup
      Gem.clear_paths

      ENV["BUNDLE_PATH"] = nil
      ENV["GEM_HOME"] = ENV["GEM_PATH"] = Path.base_system_gems.to_s
      ENV["PATH"] = ["#{Path.root}/exe", "#{Path.system_gem_path}/bin", ENV["PATH"]].join(File::PATH_SEPARATOR)

      manifest = DEPS.to_a.sort_by(&:first).map {|k, v| "#{k} => #{v}\n" }
      manifest_path = "#{Path.base_system_gems}/manifest.txt"
      # it's OK if there are extra gems
      if !File.exist?(manifest_path) || !(manifest - File.readlines(manifest_path)).empty?
        FileUtils.rm_rf(Path.base_system_gems)
        FileUtils.mkdir_p(Path.base_system_gems)
        puts "installing gems for the tests to use..."
        DEPS.sort {|a, _| a[1].nil? ? 1 : -1 }.each {|n, v| install_gem(n, v) }
        File.open(manifest_path, "w") {|f| f << manifest.join }
      end

      ENV["HOME"] = Path.home.to_s

      Gem::DefaultUserInteraction.ui = Gem::SilentUI.new
    end

    def self.install_gem(name, version = nil)
      cmd = "gem install #{name} --no-rdoc --no-ri"
      cmd += " --version '#{version}'" if version
      system(cmd) || raise("Installing gem #{name} for the tests to use failed!")
    end

    def gem_command(command, args = "", options = {})
      if command == :exec && !options[:no_quote]
        args = args.gsub(/(?=")/, "\\")
        args = %("#{args}")
      end
      lib = File.join(File.dirname(__FILE__), "..", "..", "lib")
      `#{Gem.ruby} -I#{lib} -rubygems -S gem --backtrace #{command} #{args}`.strip
    end
  end
end
