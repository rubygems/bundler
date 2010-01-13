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
      FileUtils.mkdir_p(bundled_app)
      Dir.chdir(bundled_app, &blk)
    end

    def run_in_context(cmd)
      env = bundled_path.join('environment.rb')
      raise "Missing environment.rb" unless env.file?
      @out = ruby "-r #{env}", cmd
    end

    def run(cmd)
      setup = "require 'rubygems' ; require 'bubble' ; Bubble.setup\n"
      @out = ruby(setup + cmd)
    end

    def lib
      File.expand_path('../../../lib', __FILE__)
    end

    def bbl(cmd)
      bbl = File.expand_path('../../../bin/bbl', __FILE__)
      @out = %x{#{Gem.ruby} -I#{lib} #{bbl} #{cmd}}.strip
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

    def install_gemfile(string)
      gemfile string
      bbl :install
    end

    # def bubble(*args)
    #   path = bundled_app("Gemfile")
    #   path = args.shift if Pathname === args.first
    #   str  = args.shift || ""
    #   FileUtils.mkdir_p(path.dirname)
    #   Dir.chdir(path.dirname) do
    #     gemfile(path, str)
    #     Bubble.load(path)
    #   end
    # end

    def install_gems(*gems)
      Dir["#{gem_repo1}/**/*.gem"].each do |path|
        if gems.include?(File.basename(path, ".gem"))
          gem_command :install, "--no-rdoc --no-ri --ignore-dependencies #{path}"
        end
      end
    end

    alias install_gem install_gems

    def system_gems(*gems)
      FileUtils.mkdir_p(system_gem_path)

      Gem.clear_paths

      gem_home, gem_path = ENV['GEM_HOME'], ENV['GEM_PATH']
      ENV['GEM_HOME'], ENV['GEM_PATH'] = system_gem_path.to_s, system_gem_path.to_s

      install_gems(*gems)
      if block_given?
        yield
        ENV['GEM_HOME'], ENV['GEM_PATH'] = gem_home, gem_path
      end
    end
  end
end