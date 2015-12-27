module Spec
  module Helpers
    def reset!
      @in_p = nil
      @out_p = nil
      @err_p = nil
      Dir["#{tmp}/{gems/*,*}"].each do |dir|
        next if %(base remote1 gems rubygems).include?(File.basename(dir))
        if ENV["BUNDLER_SUDO_TESTS"]
          `sudo rm -rf #{dir}`
        else
          FileUtils.rm_rf(dir)
        end
      end
      FileUtils.mkdir_p(tmp)
      FileUtils.mkdir_p(home)
      Bundler.send(:remove_instance_variable, :@settings) if Bundler.send(:instance_variable_defined?, :@settings)
    end

    attr_reader :out, :err, :exitstatus

    def in_app_root(&blk)
      Dir.chdir(bundled_app, &blk)
    end

    def in_app_root2(&blk)
      Dir.chdir(bundled_app2, &blk)
    end

    def in_app_root_custom(root, &blk)
      Dir.chdir(root, &blk)
    end

    def run(cmd, *args)
      opts = args.last.is_a?(Hash) ? args.pop : {}
      expect_err = opts.delete(:expect_err)
      env = opts.delete(:env)
      groups = args.map(&:inspect).join(", ")
      setup = "require 'rubygems' ; require 'bundler' ; Bundler.setup(#{groups})\n"
      @out = ruby(setup + cmd, :expect_err => expect_err, :env => env)
    end

    def load_error_run(ruby, name, *args)
      cmd = <<-RUBY
        begin
          #{ruby}
        rescue LoadError => e
          $stderr.puts "ZOMG LOAD ERROR" if e.message.include?("-- #{name}")
        end
      RUBY
      opts = args.last.is_a?(Hash) ? args.pop : {}
      opts.merge!(:expect_err => true)
      args += [opts]
      run(cmd, *args)
    end

    def lib
      File.expand_path("../../../lib", __FILE__)
    end

    def spec
      File.expand_path("../../../spec", __FILE__)
    end

    def bundle(cmd, options = {})
      expect_err = options.delete(:expect_err)
      with_sudo = options.delete(:sudo)
      sudo = with_sudo == :preserve_env ? "sudo -E" : "sudo" if with_sudo

      options["no-color"] = true unless options.key?("no-color") || %w(exec conf).include?(cmd.to_s[0..3])

      bundle_bin = File.expand_path("../../../exe/bundle", __FILE__)

      requires = options.delete(:requires) || []
      requires << File.expand_path("../fakeweb/" + options.delete(:fakeweb) + ".rb", __FILE__) if options.key?(:fakeweb)
      requires << File.expand_path("../artifice/" + options.delete(:artifice) + ".rb", __FILE__) if options.key?(:artifice)
      requires << "support/hax"
      requires_str = requires.map {|r| "-r#{r}" }.join(" ")

      env = (options.delete(:env) || {}).map {|k, v| "#{k}='#{v}'" }.join(" ")
      args = options.map do |k, v|
        v == true ? " --#{k}" : " --#{k} #{v}" if v
      end.join

      cmd = "#{env} #{sudo} #{Gem.ruby} -I#{lib}:#{spec} #{requires_str} #{bundle_bin} #{cmd}#{args}"
      sys_exec(cmd, expect_err) {|i| yield i if block_given? }
    end

    def bundle_ruby(options = {})
      expect_err = options.delete(:expect_err)
      options["no-color"] = true unless options.key?("no-color")

      bundle_bin = File.expand_path("../../../exe/bundle_ruby", __FILE__)

      requires = options.delete(:requires) || []
      requires << File.expand_path("../fakeweb/" + options.delete(:fakeweb) + ".rb", __FILE__) if options.key?(:fakeweb)
      requires << File.expand_path("../artifice/" + options.delete(:artifice) + ".rb", __FILE__) if options.key?(:artifice)
      requires_str = requires.map {|r| "-r#{r}" }.join(" ")

      env = (options.delete(:env) || {}).map {|k, v| "#{k}='#{v}' " }.join
      cmd = "#{env}#{Gem.ruby} -I#{lib} #{requires_str} #{bundle_bin}"

      sys_exec(cmd, expect_err) {|i| yield i if block_given? }
    end

    def ruby(ruby, options = {})
      expect_err = options.delete(:expect_err)
      env = (options.delete(:env) || {}).map {|k, v| "#{k}='#{v}' " }.join
      ruby.gsub!(/["`\$]/) {|m| "\\#{m}" }
      lib_option = options[:no_lib] ? "" : " -I#{lib}"
      sys_exec(%(#{env}#{Gem.ruby}#{lib_option} -e "#{ruby}"), expect_err)
    end

    def load_error_ruby(ruby, name, opts = {})
      cmd = <<-R
        begin
          #{ruby}
        rescue LoadError => e
          $stderr.puts "ZOMG LOAD ERROR"# if e.message.include?("-- #{name}")
        end
      R
      ruby(cmd, opts.merge(:expect_err => true))
    end

    def gembin(cmd)
      lib = File.expand_path("../../../lib", __FILE__)
      old = ENV["RUBYOPT"]
      ENV["RUBYOPT"] = "#{ENV["RUBYOPT"]} -I#{lib}"
      cmd = bundled_app("bin/#{cmd}") unless cmd.to_s.include?("/")
      sys_exec(cmd.to_s)
    ensure
      ENV["RUBYOPT"] = old
    end

    def sys_exec(cmd, expect_err = false)
      Open3.popen3(cmd.to_s) do |stdin, stdout, stderr, wait_thr|
        @in_p = stdin
        @out_p = stdout
        @err_p = stderr

        yield @in_p if block_given?
        @in_p.close

        @out = @out_p.read_available_bytes.strip
        @err = @err_p.read_available_bytes.strip
        @exitstatus = wait_thr && wait_thr.value.exitstatus
      end

      puts @err unless expect_err || @err.empty? || !$show_err
      @out
    end

    def config(config = nil, path = bundled_app(".bundle/config"))
      return YAML.load_file(path) unless config
      FileUtils.mkdir_p(File.dirname(path))
      File.open(path, "w") do |f|
        f.puts config.to_yaml
      end
      config
    end

    def global_config(config = nil)
      config(config, home(".bundle/config"))
    end

    def create_file(*args)
      path = bundled_app(args.shift)
      path = args.shift if args.first.is_a?(Pathname)
      str  = args.shift || ""
      path.dirname.mkpath
      File.open(path.to_s, "w") do |f|
        f.puts strip_whitespace(str)
      end
    end

    def gemfile(*args)
      create_file("Gemfile", *args)
    end

    def lockfile(*args)
      if args.empty?
        File.open("Gemfile.lock", "r", &:read)
      else
        create_file("Gemfile.lock", *args)
      end
    end

    def strip_whitespace(str)
      # Trim the leading spaces
      spaces = str[/\A\s+/, 0] || ""
      str.gsub(/^#{spaces}/, "")
    end

    def install_gemfile(*args)
      gemfile(*args)
      opts = args.last.is_a?(Hash) ? args.last : {}
      opts[:retry] ||= 0
      bundle :install, opts
    end

    def install_gems(*gems)
      gems.each do |g|
        path = "#{gem_repo1}/gems/#{g}.gem"

        raise "OMG `#{path}` does not exist!" unless File.exist?(path)

        gem_command :install, "--no-rdoc --no-ri --ignore-dependencies #{path}"
      end
    end

    alias_method :install_gem, :install_gems

    def with_gem_path_as(path)
      gem_home = ENV["GEM_HOME"]
      gem_path = ENV["GEM_PATH"]
      ENV["GEM_HOME"] = path.to_s
      ENV["GEM_PATH"] = path.to_s
      yield
    ensure
      ENV["GEM_HOME"] = gem_home
      ENV["GEM_PATH"] = gem_path
    end

    def with_path_as(path)
      old_path = ENV["PATH"]
      ENV["PATH"] = "#{path}:#{ENV["PATH"]}"
      yield
    ensure
      ENV["PATH"] = old_path
    end

    def break_git!
      FileUtils.mkdir_p(tmp("broken_path"))
      File.open(tmp("broken_path/git"), "w", 0755) do |f|
        f.puts "#!/usr/bin/env ruby\nSTDERR.puts 'This is not the git you are looking for'\nexit 1"
      end

      ENV["PATH"] = "#{tmp("broken_path")}:#{ENV["PATH"]}"
    end

    def fake_man!
      FileUtils.mkdir_p(tmp("fake_man"))
      File.open(tmp("fake_man/man"), "w", 0755) do |f|
        f.puts "#!/usr/bin/env ruby\nputs ARGV.inspect\n"
      end

      ENV["PATH"] = "#{tmp("fake_man")}:#{ENV["PATH"]}"
    end

    def kill_path!
      ENV["PATH"] = ""
    end

    def system_gems(*gems)
      gems = gems.flatten

      FileUtils.rm_rf(system_gem_path)
      FileUtils.mkdir_p(system_gem_path)

      Gem.clear_paths

      gem_home = ENV["GEM_HOME"]
      gem_path = ENV["GEM_PATH"]
      path = ENV["PATH"]
      ENV["GEM_HOME"] = system_gem_path.to_s
      ENV["GEM_PATH"] = system_gem_path.to_s

      install_gems(*gems)
      if block_given?
        begin
          yield
        ensure
          ENV["GEM_HOME"] = gem_home
          ENV["GEM_PATH"] = gem_path
          ENV["PATH"] = path
        end
      end
    end

    def realworld_system_gems(*gems)
      gems = gems.flatten

      FileUtils.rm_rf(system_gem_path)
      FileUtils.mkdir_p(system_gem_path)

      Gem.clear_paths

      gem_home = ENV["GEM_HOME"]
      gem_path = ENV["GEM_PATH"]
      path = ENV["PATH"]
      ENV["GEM_HOME"] = system_gem_path.to_s
      ENV["GEM_PATH"] = system_gem_path.to_s

      gems.each do |gem|
        gem_command :install, "--no-rdoc --no-ri #{gem}"
      end
      if block_given?
        begin
          yield
        ensure
          ENV["GEM_HOME"] = gem_home
          ENV["GEM_PATH"] = gem_path
          ENV["PATH"] = path
        end
      end
    end

    def cache_gems(*gems)
      gems = gems.flatten

      FileUtils.rm_rf("#{bundled_app}/vendor/cache")
      FileUtils.mkdir_p("#{bundled_app}/vendor/cache")

      gems.each do |g|
        path = "#{gem_repo1}/gems/#{g}.gem"
        raise "OMG `#{path}` does not exist!" unless File.exist?(path)
        FileUtils.cp(path, "#{bundled_app}/vendor/cache")
      end
    end

    def simulate_new_machine
      system_gems []
      FileUtils.rm_rf default_bundle_path
      FileUtils.rm_rf bundled_app(".bundle")
    end

    def simulate_platform(platform)
      old = ENV["BUNDLER_SPEC_PLATFORM"]
      ENV["BUNDLER_SPEC_PLATFORM"] = platform.to_s
      yield if block_given?
    ensure
      ENV["BUNDLER_SPEC_PLATFORM"] = old if block_given?
    end

    def simulate_ruby_engine(engine, version = "1.6.0")
      return if engine == local_ruby_engine

      old = ENV["BUNDLER_SPEC_RUBY_ENGINE"]
      ENV["BUNDLER_SPEC_RUBY_ENGINE"] = engine
      old_version = ENV["BUNDLER_SPEC_RUBY_ENGINE_VERSION"]
      ENV["BUNDLER_SPEC_RUBY_ENGINE_VERSION"] = version
      yield if block_given?
    ensure
      ENV["BUNDLER_SPEC_RUBY_ENGINE"] = old if block_given?
      ENV["BUNDLER_SPEC_RUBY_ENGINE_VERSION"] = old_version if block_given?
    end

    def simulate_bundler_version(version)
      old = ENV["BUNDLER_SPEC_VERSION"]
      ENV["BUNDLER_SPEC_VERSION"] = version.to_s
      yield if block_given?
    ensure
      ENV["BUNDLER_SPEC_VERSION"] = old if block_given?
    end

    def simulate_windows
      old = ENV["BUNDLER_SPEC_WINDOWS"]
      ENV["BUNDLER_SPEC_WINDOWS"] = "true"
      simulate_platform mswin do
        yield
      end
    ensure
      ENV["BUNDLER_SPEC_WINDOWS"] = old
    end

    def revision_for(path)
      Dir.chdir(path) { `git rev-parse HEAD`.strip }
    end

    def capture_output
      fake_stdout = StringIO.new
      actual_stdout = $stdout
      $stdout = fake_stdout
      yield
      fake_stdout.rewind
      fake_stdout.read
    ensure
      $stdout = actual_stdout
    end

    def with_read_only(pattern)
      chmod = lambda do |dirmode, filemode|
        lambda do |f|
          mode = File.directory?(f) ? dirmode : filemode
          File.chmod(mode, f)
        end
      end

      Dir[pattern].each(&chmod[0555, 0444])
      yield
    ensure
      Dir[pattern].each(&chmod[0755, 0644])
    end

    def process_file(pathname)
      changed_lines = pathname.readlines.map do |line|
        yield line
      end
      File.open(pathname, "w") {|file| file.puts(changed_lines.join) }
    end

    def with_env_vars(env_hash, &block)
      current_values = {}
      env_hash.each do |k, v|
        current_values[k] = ENV[k]
        ENV[k] = v
      end
      block.call if block_given?
      env_hash.each do |k, _|
        ENV[k] = current_values[k]
      end
    end

    def require_rack
      # need to hack, so we can require rack
      old_gem_home = ENV["GEM_HOME"]
      ENV["GEM_HOME"] = Spec::Path.base_system_gems.to_s
      require "rack"
      ENV["GEM_HOME"] = old_gem_home
    end

    def wait_for_server(host, port, seconds = 15)
      tries = 0
      sleep 0.5
      TCPSocket.new(host, port)
    rescue => e
      raise(e) if tries > (seconds * 2)
      tries += 1
      retry
    end

    def find_unused_port
      tcp_server = TCPServer.new("127.0.0.1", 0) # Use any available ephemeral port
      port = tcp_server.addr[1]
      tcp_server.close
      port
    end
  end
end
