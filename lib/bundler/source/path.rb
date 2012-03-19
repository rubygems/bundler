module Bundler
  module Source
    class Path
      class Installer < Bundler::GemInstaller
        def initialize(spec, options = {})
          @spec              = spec
          @bin_dir           = Bundler.requires_sudo? ? "#{Bundler.tmp}/bin" : "#{Bundler.rubygems.gem_dir}/bin"
          @gem_dir           = Bundler.rubygems.path(spec.full_gem_path)
          @wrappers          = options[:wrappers] || true
          @env_shebang       = options[:env_shebang] || true
          @format_executable = options[:format_executable] || false
        end

        def generate_bin
          return if spec.executables.nil? || spec.executables.empty?

          if Bundler.requires_sudo?
            FileUtils.mkdir_p("#{Bundler.tmp}/bin") unless File.exist?("#{Bundler.tmp}/bin")
          end
          super
          if Bundler.requires_sudo?
            Bundler.mkdir_p "#{Bundler.rubygems.gem_dir}/bin"
            spec.executables.each do |exe|
              Bundler.sudo "cp -R #{Bundler.tmp}/bin/#{exe} #{Bundler.rubygems.gem_dir}/bin/"
            end
          end
        end
      end

      attr_reader   :path, :options
      attr_writer   :name
      attr_accessor :version

      DEFAULT_GLOB = "{,*,*/*}.gemspec"

      def initialize(options)
        @options = options
        @glob    = options["glob"] || DEFAULT_GLOB
        @name    = options["name"]
        @version = options["version"]

        @allow_cached = false
        @allow_remote = false

        if options["path"]
          @path = Pathname.new(options["path"])
          @path = @path.expand_path(Bundler.root) unless @path.relative?
        end

        @path = app_cache_path if has_app_cache?
      end

      def remote!
        @allow_remote = true
      end

      def cached!
        @allow_cached = true
      end

      def hash
        self.class.hash
      end

      def self.from_lock(options)
        new(options.merge("path" => options.delete("remote")))
      end

      def to_lock
        out = "PATH\n"
        out << "  remote: #{relative_path}\n"
        out << "  glob: #{@glob}\n" unless @glob == DEFAULT_GLOB
        out << "  specs:\n"
      end

      def to_s
        "source at #{@path}"
      end

      def eql?(o)
        o.instance_of?(Path) &&
        path.expand_path(Bundler.root) == o.path.expand_path(Bundler.root) &&
        version == o.version
      end

      alias == eql?

      def name
        File.basename(path.expand_path(Bundler.root).to_s)
      end

      def install(spec)
        Bundler.ui.info "Using #{spec.name} (#{spec.version}) from #{to_s} "
        # Let's be honest, when we're working from a path, we can't
        # really expect native extensions to work because the whole point
        # is to just be able to modify what's in that path and go. So, let's
        # not put ourselves through the pain of actually trying to generate
        # the full gem.
        Installer.new(spec).generate_bin
      end

      def cache(spec)
        return if path.expand_path(Bundler.root).to_s.index(Bundler.root.to_s) == 0
        FileUtils.rm_rf(app_cache_path)
        FileUtils.cp_r("#{path}/.", app_cache_path)
      end

      def local_specs(*)
        @local_specs ||= load_spec_files
      end

      alias :specs :local_specs

    private

      def app_cache_path
        @app_cache_path ||= Bundler.app_cache.join(name)
      end

      def has_app_cache?
        SharedHelpers.in_bundle? && app_cache_path.exist?
      end

      def load_spec_files
        index = Index.new
        expanded_path = path.expand_path(Bundler.root)

        if File.directory?(expanded_path)
          Dir["#{expanded_path}/#{@glob}"].each do |file|
            spec = Bundler.load_gemspec(file)
            if spec
              spec.loaded_from = file.to_s
              spec.source = self
              index << spec
            end
          end

          if index.empty? && @name && @version
            index << Gem::Specification.new do |s|
              s.name     = @name
              s.source   = self
              s.version  = Gem::Version.new(@version)
              s.platform = Gem::Platform::RUBY
              s.summary  = "Fake gemspec for #{@name}"
              s.relative_loaded_from = "#{@name}.gemspec"
              s.authors  = ["no one"]
              if expanded_path.join("bin").exist?
                executables = expanded_path.join("bin").children
                executables.reject!{|p| File.directory?(p) }
                s.executables = executables.map{|c| c.basename.to_s }
              end
            end
          end
        else
          raise PathError, "The path `#{expanded_path}` does not exist."
        end

        index
      end

      def relative_path
        if path.to_s.match(%r{^#{Bundler.root.to_s}})
          return path.relative_path_from(Bundler.root)
        end
        path
      end
    end
  end
end