# frozen_string_literal: true
require "pathname"
require "rubygems"

require "bundler/constants"
require "bundler/rubygems_integration"
require "bundler/current_ruby"

module Gem
  class Dependency
    unless method_defined? :requirement
      def requirement
        version_requirements
      end
    end
  end
end

module Bundler
  module SharedHelpers
    attr_accessor :gem_loaded

    def default_gemfile
      gemfile = find_gemfile
      raise GemfileNotFound, "Could not locate Gemfile" unless gemfile
      Pathname.new(gemfile)
    end

    def default_lockfile
      gemfile = default_gemfile

      case gemfile.basename.to_s
      when "gems.rb" then Pathname.new(gemfile.sub(/.rb$/, ".locked"))
      else Pathname.new("#{gemfile}.lock")
      end
    end

    def default_bundle_dir
      bundle_dir = find_directory(".bundle")
      return nil unless bundle_dir

      global_bundle_dir = File.join(Bundler.rubygems.user_home, ".bundle")
      return nil if bundle_dir == global_bundle_dir

      Pathname.new(bundle_dir)
    end

    def in_bundle?
      find_gemfile
    end

    def chdir(dir, &blk)
      Bundler.rubygems.ext_lock.synchronize do
        Dir.chdir dir, &blk
      end
    end

    def pwd
      Bundler.rubygems.ext_lock.synchronize do
        Pathname.pwd
      end
    end

    def with_clean_git_env(&block)
      keys    = %w(GIT_DIR GIT_WORK_TREE)
      old_env = keys.inject({}) do |h, k|
        h.update(k => ENV[k])
      end

      keys.each {|key| ENV.delete(key) }

      block.call
    ensure
      keys.each {|key| ENV[key] = old_env[key] }
    end

    def set_bundle_environment
      set_bundle_variables
      set_path
      set_rubyopt
      set_rubylib
    end

    # Rescues permissions errors raised by file system operations
    # (ie. Errno:EACCESS, Errno::EAGAIN) and raises more friendly errors instead.
    #
    # @param path [String] the path that the action will be attempted to
    # @param action [Symbol, #to_s] the type of operation that will be
    #   performed. For example: :write, :read, :exec
    #
    # @yield path
    #
    # @raise [Bundler::PermissionError] if Errno:EACCES is raised in the
    #   given block
    # @raise [Bundler::TemporaryResourceError] if Errno:EAGAIN is raised in the
    #   given block
    #
    # @example
    #   filesystem_access("vendor/cache", :write) do
    #     FileUtils.mkdir_p("vendor/cache")
    #   end
    #
    # @see {Bundler::PermissionError}
    def filesystem_access(path, action = :write)
      yield path
    rescue Errno::EACCES
      raise PermissionError.new(path, action)
    rescue Errno::EAGAIN
      raise TemporaryResourceError.new(path, action)
    rescue Errno::EPROTO
      raise VirtualProtocolError.new
    rescue *[const_get_safely(:ENOTSUP, Errno)].compact
      raise OperationNotSupportedError.new(path, action)
    end

    def const_get_safely(constant_name, namespace)
      const_in_namespace = namespace.constants.include?(constant_name.to_s) ||
        namespace.constants.include?(constant_name.to_sym)
      return nil unless const_in_namespace
      namespace.const_get(constant_name)
    end

    def major_deprecation(message)
      return unless prints_major_deprecations?
      @major_deprecation_ui ||= Bundler::UI::Shell.new("no-color" => true)
      ui = Bundler.ui.is_a?(@major_deprecation_ui.class) ? Bundler.ui : @major_deprecation_ui
      ui.warn("[DEPRECATED FOR #{Bundler::VERSION.split(".").first.to_i + 1}.0] #{message}")
    end

    def print_major_deprecations!
      if RUBY_VERSION < "2"
        major_deprecation("Bundler will only support ruby >= 2.0, you are running #{RUBY_VERSION}")
      end
      unless Bundler.rubygems.provides?(">= 2")
        major_deprecation("Bundler will only support rubygems >= 2.4, you are running #{self.class.version}")
      end
    end

  private

    def find_gemfile
      given = ENV["BUNDLE_GEMFILE"]
      return given if given && !given.empty?

      find_file("Gemfile", "gems.rb")
    end

    def find_file(*names)
      search_up(*names) do |filename|
        return filename if File.file?(filename)
      end
    end

    def find_directory(*names)
      search_up(*names) do |dirname|
        return dirname if File.directory?(dirname)
      end
    end

    def search_up(*names)
      previous = nil
      current  = File.expand_path(SharedHelpers.pwd)

      until !File.directory?(current) || current == previous
        if ENV["BUNDLE_SPEC_RUN"]
          # avoid stepping above the tmp directory when testing
          return nil if File.file?(File.join(current, "bundler.gemspec"))
        end

        names.each do |name|
          filename = File.join(current, name)
          yield filename
        end
        previous = current
        current = File.expand_path("..", current)
      end
    end

    def set_bundle_variables
      begin
        ENV["BUNDLE_BIN_PATH"] = Bundler.rubygems.bin_path("bundler", "bundle", VERSION)
      rescue Gem::GemNotFoundException
        ENV["BUNDLE_BIN_PATH"] = File.expand_path("../../../exe/bundle", __FILE__)
      end

      # Set BUNDLE_GEMFILE
      ENV["BUNDLE_GEMFILE"] = find_gemfile.to_s
      ENV["BUNDLER_VERSION"] = Bundler::VERSION
    end

    def set_path
      paths = (ENV["PATH"] || "").split(File::PATH_SEPARATOR)
      paths.unshift "#{Bundler.bundle_path}/bin"
      ENV["PATH"] = paths.uniq.join(File::PATH_SEPARATOR)
    end

    def set_rubyopt
      rubyopt = [ENV["RUBYOPT"]].compact
      return if !rubyopt.empty? && rubyopt.first =~ %r{-rbundler/setup}
      rubyopt.unshift %(-rbundler/setup)
      ENV["RUBYOPT"] = rubyopt.join(" ")
    end

    def set_rubylib
      rubylib = (ENV["RUBYLIB"] || "").split(File::PATH_SEPARATOR)
      rubylib.unshift File.expand_path("../..", __FILE__)
      ENV["RUBYLIB"] = rubylib.uniq.join(File::PATH_SEPARATOR)
    end

    def clean_load_path
      # handle 1.9 where system gems are always on the load path
      if defined?(::Gem)
        me = File.expand_path("../../", __FILE__)
        me = /^#{Regexp.escape(me)}/

        loaded_gem_paths = Bundler.rubygems.loaded_gem_paths

        $LOAD_PATH.reject! do |p|
          next if File.expand_path(p) =~ me
          loaded_gem_paths.delete(p)
        end
        $LOAD_PATH.uniq!
      end
    end

    def prints_major_deprecations?
      require "bundler"
      return false unless Bundler.settings[:major_deprecations]
      require "bundler/deprecate"
      return false if Bundler::Deprecate.skip
      true
    end

    extend self
  end
end
