module Spec
  module Helpers
    def run_in_context(*args)
      cmd = args.pop.gsub(/(?=")/, "\\")
      env = args.pop || bundled_app("vendor", "gems", "environment")
      lib = File.join(File.dirname(__FILE__), '..', '..', 'lib')
      %x{#{Gem.ruby} -I#{lib} -r #{env} -e "#{cmd}"}.strip
    end

    def gem_command(command, args = "")
      if command == :exec
        args = args.gsub(/(?=")/, "\\")
        args = %["#{args}"]
      end
      lib  = File.join(File.dirname(__FILE__), '..', '..', 'lib')
      %x{#{Gem.ruby} -I#{lib} -rubygems -S gem #{command} #{args}}.strip
    end

    def build_manifest_file(*args)
      path = bundled_app("Gemfile")
      path = args.shift if args.first.is_a?(Pathname)
      str  = args.shift || ""
      FileUtils.mkdir_p(path.dirname)
      File.open(path, 'w') do |f|
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

    def reset!
      tmp_path.rmtree if tmp_path.exist?
      tmp_path.mkdir
    end
  end
end