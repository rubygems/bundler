module Spec
  module Helpers
    def reset!
      Dir["#{tmp}/{gems/*,*}"].each do |dir|
        next if %(base remote1 gems).include?(File.basename(dir))
        FileUtils.rm_rf(dir)
      end
      FileUtils.mkdir_p(tmp)
      FileUtils.mkdir_p(home)
      Gem.sources = ["file://#{gem_repo1}/"]
      Gem.configuration.write
    end

    attr_reader :out

    def in_app_root(&blk)
      Dir.chdir(bundled_app, &blk)
    end

    def in_app_root2(&blk)
      Dir.chdir(bundled_app2, &blk)
    end

    def run_in_context(cmd)
      env = bundled_path.join('environment.rb')
      raise "Missing environment.rb" unless env.file?
      @out = ruby "-r #{env}", cmd
    end

    def run(cmd, *args)
      groups = args.map {|a| a.inspect }.join(", ")
      setup = "require 'rubygems' ; require 'bundler' ; Bundler.setup(#{groups})\n"
      @out = ruby(setup + cmd)
    end

    def lib
      File.expand_path('../../../lib', __FILE__)
    end

    def bundle(cmd, options = {})
      args = options.map { |k,v| " --#{k} #{v}"}.join
      gemfile = File.expand_path('../../../bin/bundle', __FILE__)
      @out = %x{#{Gem.ruby} -I#{lib} #{gemfile} #{cmd}#{args}}.strip
    end

    def ruby(opts, ruby = nil)
      ruby, opts = opts, nil unless ruby
      ruby.gsub!(/(?=")/, "\\")
      ruby.gsub!('$', '\\$')
      %x{#{Gem.ruby} -I#{lib} #{opts} -e "#{ruby}"}.strip
    end

    def gemfile(*args)
      path = bundled_app("Gemfile")
      path = args.shift if Pathname === args.first
      str  = args.shift || ""
      FileUtils.mkdir_p(path.dirname.to_s)
      File.open(path.to_s, 'w') do |f|
        f.puts str
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

      gem_home, gem_path = ENV['GEM_HOME'], ENV['GEM_PATH']
      ENV['GEM_HOME'], ENV['GEM_PATH'] = system_gem_path.to_s, system_gem_path.to_s

      install_gems(*gems)
      if block_given?
        begin
          yield
        ensure
          ENV['GEM_HOME'], ENV['GEM_PATH'] = gem_home, gem_path
        end
      end
    end

    def revision_for(path)
      Dir.chdir(path) { `git rev-parse HEAD`.strip }
    end
  end
end