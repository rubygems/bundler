module Bundler
  class CLI::Exec
    attr_reader :options, :args, :cmd

    def initialize(options, args)
      @options = options
      @cmd = args.shift
      @args = args

      if RUBY_VERSION >= "2.0"
        @args << { :close_others => !options.keep_file_descriptors? }
      elsif options.keep_file_descriptors?
        Bundler.ui.warn "Ruby version #{RUBY_VERSION} defaults to keeping non-standard file descriptors on Kernel#exec."
      end
    end

    def run
      begin
        if cmd.nil?
          raise ArgumentError.new
        end

        execute_within_path
      rescue Errno::EACCES
        Bundler.ui.error "bundler: not executable: #{cmd}"
        exit 126
      rescue Errno::ENOENT
        Bundler.ui.error "bundler: command not found: #{cmd}"
        Bundler.ui.warn  "Install missing gem executables with `bundle install`"
        exit 127
      rescue ArgumentError
        Bundler.ui.error "bundler: exec needs a command to run"
        exit 128
      end
    end

    private

    def execute_within_path
      if RUBY_VERSION >= "1.9"
        path.each do |path|
          bin_path = File.join(path, @cmd)
          if bin_path == Bundler.which(@cmd)
            Kernel.exec(build_env, bin_path, *args)
          end
        end
      end

      # fallback
      Bundler.definition.validate_ruby!
      Bundler.load.setup_environment
      Kernel.exec(@cmd, *args)
    end

    def path
      ENV['PATH'].split(":").map { |p| File.expand_path(p) }
    end

    def build_env
      rubyopt = [ENV["RUBYOPT"]].compact
      if rubyopt.empty? || rubyopt.first !~ /-rbundler\/setup/
        rubyopt << %|-rbundler/setup|
      end

      rubylib = (ENV["RUBYLIB"] || "").split(File::PATH_SEPARATOR)
      rubylib.unshift File.expand_path('../../..', __FILE__)

      {
        'RUBYOPT' => rubyopt.join(' '),
        'RUBYLIB' => rubylib.uniq.join(File::PATH_SEPARATOR),
        'FORCE_TTY' => 'true'
      }
    end

    def env_string
      build_env.to_a.map { |k| "#{k[0]}=#{k[1]}"}.join(" ")
    end

  end
end
