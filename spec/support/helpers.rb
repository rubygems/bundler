module Spec
  module Helpers
    def reset!
      Dir["#{tmp}/{gems/*,*}"].each do |dir|
        next if %(base remote1 gems rubygems_1_3_5 rubygems_1_3_6 rubygems_master).include?(File.basename(dir))
        FileUtils.rm_rf(dir)
      end
      FileUtils.mkdir_p(tmp)
      FileUtils.mkdir_p(home)
      Gem.sources = ["file://#{gem_repo1}/"]
      Gem.configuration.write
    end

    attr_reader :out, :err

    def in_app_root(&blk)
      Dir.chdir(bundled_app, &blk)
    end

    def in_app_root2(&blk)
      Dir.chdir(bundled_app2, &blk)
    end

    def run(cmd, *args)
      opts = args.last.is_a?(Hash) ? args.pop : {}
      expect_err = opts.delete(:expect_err)
      groups = args.map {|a| a.inspect }.join(", ")

      if opts[:lite_runtime]
        setup = "require '#{bundled_app(".bundle/environment")}' ; Bundler.setup(#{groups})\n"
      else
        setup = "require 'rubygems' ; require 'bundler' ; Bundler.setup(#{groups})\n"
      end

      @out = ruby(setup + cmd, :expect_err => expect_err)
    end

    def lib
      File.expand_path('../../../lib', __FILE__)
    end

    def bundle(cmd, options = {})
      expect_err = options.delete(:expect_err)
      env = (options.delete(:env) || {}).map{|k,v| "#{k}='#{v}' "}.join
      args = options.map { |k,v| " --#{k} #{v}"}.join
      gemfile = File.expand_path('../../../bin/bundle', __FILE__)
      sys_exec("#{env}#{Gem.ruby} -I#{lib} #{gemfile} #{cmd}#{args}", expect_err)
    end

    def ruby(ruby, options = {})
      expect_err = options.delete(:expect_err)
      ruby.gsub!(/(?=")/, "\\")
      ruby.gsub!('$', '\\$')
      sys_exec(%'#{Gem.ruby} -I#{lib} -e "#{ruby}"', expect_err)
    end

    def sys_exec(cmd, expect_err = false)
      require "open3"
      input, out, err, waitthread = Open3.popen3(cmd)
      @err = err.read.strip
      puts @err if !expect_err && $show_err && !@err.empty?
      @out = out.read.strip
      @exitstatus = nil
      @exitstatus = waitthread.value.to_i if waitthread
      @out
    end

    def config(config = nil)
      path = bundled_app('.bundle/config')
      return YAML.load_file(path) unless config
      FileUtils.mkdir_p(File.dirname(path))
      File.open(path, 'w') do |f|
        f.puts config.to_yaml
      end
      config
    end

    def gemfile(*args)
      path = bundled_app("Gemfile")
      path = args.shift if Pathname === args.first
      str  = args.shift || ""
      path.dirname.mkpath
      File.open(path.to_s, 'w') do |f|
        f.puts str
      end
    end

    def env_file(*args)
      path = bundled_app(".bundle/environment.rb")
      if args.empty?
        path
      else
        str = args.shift || ""
        File.open(path, 'w'){|f| f.puts str }
      end
    end

    def install_gemfile(*args)
      gemfile(*args)
      opts = args.last.is_a?(Hash) ? args.last : {}
      bundle :install, opts
    end

    def install_gems(*gems)
      gems.each do |g|
        path = "#{gem_repo1}/gems/#{g}.gem"

        raise "OMG `#{path}` does not exist!" unless File.exist?(path)

        gem_command :install, "--no-rdoc --no-ri --ignore-dependencies #{path}"
      end
    end

    alias install_gem install_gems

    def with_gem_path_as(path)
      gem_home, gem_path = ENV['GEM_HOME'], ENV['GEM_PATH']
      ENV['GEM_HOME'], ENV['GEM_PATH'] = path.to_s, path.to_s
      yield
    ensure
      ENV['GEM_HOME'], ENV['GEM_PATH'] = gem_home, gem_path
    end

    def system_gems(*gems)
      gems = gems.flatten

      FileUtils.rm_rf(system_gem_path)
      FileUtils.mkdir_p(system_gem_path)

      Gem.clear_paths

      gem_home, gem_path, path = ENV['GEM_HOME'], ENV['GEM_PATH'], ENV['PATH']
      ENV['GEM_HOME'], ENV['GEM_PATH'] = system_gem_path.to_s, system_gem_path.to_s
      ENV['PATH'] = "#{system_gem_path}/bin:#{ENV['PATH']}"

      install_gems(*gems)
      if block_given?
        begin
          yield
        ensure
          ENV['GEM_HOME'], ENV['GEM_PATH'] = gem_home, gem_path
          ENV['PATH'] = path
        end
      end
    end

    def simulate_new_machine
      system_gems []
      FileUtils.rm_rf default_bundle_path
      FileUtils.rm_rf bundled_app('.bundle')
    end

    def revision_for(path)
      Dir.chdir(path) { `git rev-parse HEAD`.strip }
    end
  end
end
