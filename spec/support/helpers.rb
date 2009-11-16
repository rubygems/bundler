module Spec
  module Helpers
    def run_in_context(cmd)
      env = bundled_app("vendor", "gems", "environment")
      ruby "-r #{env}", cmd
    end

    def ruby(opts, ruby = nil)
      ruby, opts = opts, nil unless ruby
      ruby.gsub!(/(?=")/, "\\")
      lib = File.join(File.dirname(__FILE__), '..', '..', 'lib')
      %x{#{Gem.ruby} -I#{lib} #{opts} -e "#{ruby}"}.strip
    end

    def gem_command(command, args = "", options = {})
      if command == :exec && !options[:no_quote]
        args = args.gsub(/(?=")/, "\\")
        args = %["#{args}"]
      end
      lib  = File.join(File.dirname(__FILE__), '..', '..', 'lib')
      %x{#{Gem.ruby} -I#{lib} -rubygems -S gem --backtrace #{command} #{args}}.strip
    end

    def build_manifest_file(*args)
      path = bundled_app("Gemfile")
      path = args.shift if args.first.is_a?(Pathname)
      str  = args.shift || ""
      FileUtils.mkdir_p(path.dirname.to_s)
      File.open(path.to_s, 'w') do |f|
        f.puts str
      end
    end

    def build_manifest(*args)
      path = bundled_app("Gemfile")
      path = args.shift if args.first.is_a?(Pathname)
      str  = args.shift || ""
      FileUtils.mkdir_p(path.dirname)
      Dir.chdir(path.dirname) do
        build_manifest_file(path, str)
        Bundler::Environment.load(path)
      end
    end

    def install_manifest(*args)
      m = build_manifest(*args)
      m.install
      m
    end

    def build_git_repo(name, options = {})
      name = name.to_s
      with = options[:with] or raise "Omg, need to specify :with"
      path = tmp_path.join("git", name)
      path.parent.mkdir_p
      with.cp_r(path)
      if spec = options[:spec]
        File.open(path.join("#{name}.gemspec"), 'w') do |file|
          file.puts spec.to_ruby
        end
      end
      Dir.chdir(path) do
        `git init`
        `git add *`
        `git commit -m "OMG GITZ"`
        `git checkout --quiet -b alt`
        path.join("lib", name).mkdir_p
        File.open(path.join("lib", name, "in_a_branch.rb"), 'w') do |file|
          file.puts "OMG_IN_A_BRANCH = 'tagged'"
        end
        `git add *`
        `git commit -m "OMG TAGGING"`
        `git tag tagz`
        File.open(path.join("lib", name, "in_a_branch.rb"), 'w') do |file|
          file.puts "OMG_IN_A_BRANCH = 'branch'"
        end
        `git add *`
        `git commit -m "OMG BRANCHING"`
        `git checkout --quiet master`
      end
      path
    end

    def gitify(path)
      Dir.chdir(path) do
        `git init && git add * && git commit -m "OMG GITZ"`
      end
    end

    def install_gems(*gems)
      Dir["#{tmp_path}/repos/**/*.gem"].each do |path|
        if gems.include?(File.basename(path, ".gem"))
          gem_command :install, "--no-rdoc --no-ri --ignore-dependencies #{path}"
        end
      end
    end

    alias install_gem install_gems

    def system_gems(*gems)
      system_gem_path.mkdir_p

      gem_home, gem_path = ENV['GEM_HOME'], ENV['GEM_PATH']
      ENV['GEM_HOME'], ENV['GEM_PATH'] = system_gem_path.to_s, system_gem_path.to_s

      install_gems(*gems)
      yield
      ENV['GEM_HOME'], ENV['GEM_PATH'] = gem_home, gem_path
    end

    def reset!
      Dir["#{tmp_path}/*"].each do |file|
        FileUtils.rm_rf(file) unless File.basename(file) == "repos"
      end
      FileUtils.mkdir_p(tmp_path)
    end
  end
end