# frozen_string_literal: true

require "rbconfig"
require "find"

module Bundler
  class CLI::Doctor
    DARWIN_REGEX = /\s+(.+) \(compatibility /
    LDD_REGEX = /\t\S+ => (\S+) \(\S+\)/

    attr_reader :options

    def initialize(options)
      @options = options
    end

    def otool_available?
      Bundler.which("otool")
    end

    def ldd_available?
      Bundler.which("ldd")
    end

    def dylibs_darwin(path)
      output = `/usr/bin/otool -L "#{path}"`.chomp
      dylibs = output.split("\n")[1..-1].map {|l| l.match(DARWIN_REGEX).captures[0] }.uniq
      # ignore @rpath and friends
      dylibs.reject {|dylib| dylib.start_with? "@" }
    end

    def dylibs_ldd(path)
      output = `/usr/bin/ldd "#{path}"`.chomp
      output.split("\n").map do |l|
        match = l.match(LDD_REGEX)
        next if match.nil?
        match.captures[0]
      end.compact
    end

    def dylibs(path)
      case RbConfig::CONFIG["host_os"]
      when /darwin/
        return [] unless otool_available?
        dylibs_darwin(path)
      when /(linux|solaris|bsd)/
        return [] unless ldd_available?
        dylibs_ldd(path)
      else # Windows, etc.
        Bundler.ui.warn("Dynamic library check not supported on this platform.")
        []
      end
    end

    def bundles_for_gem(spec)
      Dir.glob("#{spec.full_gem_path}/**/*.bundle")
    end

    def check!
      require "bundler/cli/check"
      Bundler::CLI::Check.new({}).run
    end

    def run
      check_home_permissions
      Bundler.ui.level = "error" if options[:quiet]
      Bundler.settings.validate!
      check!

      definition = Bundler.definition
      broken_links = {}

      definition.specs.each do |spec|
        bundles_for_gem(spec).each do |bundle|
          bad_paths = dylibs(bundle).select {|f| !File.exist?(f) }
          if bad_paths.any?
            broken_links[spec] ||= []
            broken_links[spec].concat(bad_paths)
          end
        end
      end

      if broken_links.any?
        message = "The following gems are missing OS dependencies:"
        broken_links.map do |spec, paths|
          paths.uniq.map do |path|
            "\n * #{spec.name}: #{path}"
          end
        end.flatten.sort.each {|m| message += m }
        raise ProductionError, message
      else
        Bundler.ui.info "No issues found with the installed bundle"
      end
    end

  private

    def check_home_permissions
      check_for_files_not_owned_by_current_user_but_still_rw
      check_for_files_not_readable_or_writable
    end

    def check_for_files_not_owned_by_current_user_but_still_rw
      return unless any_files_not_owned_by_current_user_but_still_rw?
      Bundler.ui.warn "Files exist in Bundler home that are owned by another " \
        "user, but are stil readable/writable"
    end

    def check_for_files_not_readable_or_writable
      return unless any_files_not_readable_or_writable?
      raise ProductionError, "Files exist in Bundler home that are not " \
        "readable/writable to the current user"
    end

    def any_files_not_readable_or_writable?
      Find.find(Bundler.home.to_s).any? do |f|
        !(File.writable?(f) && File.readable?(f))
      end
    end

    def any_files_not_owned_by_current_user_but_still_rw?
      Find.find(Bundler.home.to_s).any? do |f|
        (File.stat(f).uid != Process.uid) &&
          (File.writable?(f) && File.readable?(f))
      end
    end
  end
end
