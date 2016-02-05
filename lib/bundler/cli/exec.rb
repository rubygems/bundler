# frozen_string_literal: true
require "bundler/current_ruby"

module Bundler
  class CLI::Exec
    attr_reader :options, :args, :cmd

    def initialize(options, args)
      @options = options
      @cmd = args.shift
      @args = args

      if Bundler.current_ruby.ruby_2? && !Bundler.current_ruby.jruby?
        @args << { :close_others => !options.keep_file_descriptors? }
      elsif options.keep_file_descriptors?
        Bundler.ui.warn "Ruby version #{RUBY_VERSION} defaults to keeping non-standard file descriptors on Kernel#exec."
      end
    end

    def run
      validate_cmd!
      SharedHelpers.set_bundle_environment
      if bin_path = Bundler.which(cmd)
        kernel_load(bin_path, *args) && return if ruby_shebang?(bin_path)
        # First, try to exec directly to something in PATH
        kernel_exec([bin_path, cmd], *args)
      else
        # Just exec using the given command
        kernel_exec(cmd, *args)
      end
    end

  private

    def validate_cmd!
      return unless cmd.nil?
      Bundler.ui.error "bundler: exec needs a command to run"
      exit 128
    end

    def kernel_exec(*args)
      ui = Bundler.ui
      Bundler.ui = nil
      Kernel.exec(*args)
    rescue Errno::EACCES, Errno::ENOEXEC
      Bundler.ui = ui
      Bundler.ui.error "bundler: not executable: #{cmd}"
      exit 126
    rescue Errno::ENOENT
      Bundler.ui = ui
      Bundler.ui.error "bundler: command not found: #{cmd}"
      Bundler.ui.warn "Install missing gem executables with `bundle install`"
      exit 127
    end

    def kernel_load(file, *args)
      args.pop if args.last.is_a?(Hash)
      ARGV.replace(args)
      ui = Bundler.ui
      Bundler.ui = nil
      require "bundler/setup"
      Kernel.load(file)
    rescue SystemExit
      raise
    rescue Exception => e # rubocop:disable Lint/RescueException
      Bundler.ui = ui
      Bundler.ui.error "bundler: failed to load command: #{cmd} (#{file})"
      abort "#{e.class}: #{e.message}\n#{e.backtrace.join("\n  ")}"
    end

    def ruby_shebang?(file)
      first_line = File.open(file, "rb", &:readline)
      first_line == "#!/usr/bin/env ruby\n" || first_line == "#!#{Gem.ruby}\n"
    end
  end
end
