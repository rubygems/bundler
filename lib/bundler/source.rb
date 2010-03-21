require "uri"
require "rubygems/spec_fetcher"
require "rubygems/format"
require "digest/sha1"
require "open3"

module Bundler
  module Source
    class Rubygems
      attr_reader :uri, :options

      def initialize(options = {})
        @options = options
        @uri = options["uri"].to_s
        @uri = "#{uri}/" unless @uri =~ %r'/$'
        @uri = URI.parse(@uri) unless @uri.is_a?(URI)
        raise ArgumentError, "The source must be an absolute URI" unless @uri.absolute?
      end

      def to_s
        "rubygems repository at #{uri}"
      end

      def specs
        @specs ||= fetch_specs
      end

      def fetch(spec)
        Bundler.ui.debug "  * Downloading"
        Gem::RemoteFetcher.fetcher.download(spec, uri, Gem.dir)
      end

      def install(spec)
        Bundler.ui.debug "  * Installing"
        installer = Gem::Installer.new gem_path(spec),
          :install_dir         => Gem.dir,
          :ignore_dependencies => true,
          :wrappers            => true,
          :env_shebang         => true,
          :bin_dir             => "#{Gem.dir}/bin"

        installer.install

        spec.loaded_from = "#{Gem.dir}/specifications/#{spec.full_name}.gemspec"
      end

    private

      def gem_path(spec)
        "#{Gem.dir}/cache/#{spec.full_name}.gem"
      end

      def fetch_specs
        index = Index.new
        Bundler.ui.info "Fetching source index from #{uri}"
        old, Gem.sources = Gem.sources, ["#{uri}"]

        fetch_all_specs do |n,v|
          v.each do |name, version, platform|
            next unless Gem::Platform.match(platform)
            spec = RemoteSpecification.new(name, version, platform, @uri)
            spec.source = self
            index << spec
          end
        end

        index
      ensure
        Gem.sources = old
      end

      def fetch_all_specs(&blk)
        Gem::SpecFetcher.new.list(true, false).each(&blk)
        Gem::SpecFetcher.new.list(false, true).each(&blk)
      end
    end

    class SystemGems
      def specs
        @specs ||= begin
          index = Index.new

          Gem::SourceIndex.from_installed_gems.to_a.reverse.each do |name, spec|
            spec.source = self
            index << spec
          end

          index
        end
      end

      def to_s
        "system gems"
      end

      def install(spec)
        Bundler.ui.debug "  * already installed; skipping"
      end
    end

    class GemCache
      def initialize(options)
        @path = options["path"]
      end

      def to_s
        ".gem files at #{@path}"
      end

      def specs
        @specs ||= begin
          index = Index.new

          Dir["#{@path}/*.gem"].each do |gemfile|
            spec = Gem::Format.from_file_by_path(gemfile).spec
            spec.source = self
            index << spec
          end

          index
        end
      end

      def install(spec)
        destination = Gem.dir

        Bundler.ui.debug "  * Installing from cache"
        installer = Gem::Installer.new "#{@path}/#{spec.full_name}.gem",
          :install_dir         => Gem.dir,
          :ignore_dependencies => true,
          :wrappers            => true,
          :env_shebang         => true,
          :bin_dir             => "#{Gem.dir}/bin"

        installer.install
        spec.loaded_from = "#{Gem.dir}/specifications/#{spec.full_name}.gemspec"
      end
    end

    class Path
      attr_reader :path, :options, :default_spec

      def initialize(options)
        @options = options
        @glob = options["glob"] || "{,*/}*.gemspec"

        if options["path"]
          @path = Pathname.new(options["path"]).expand_path(Bundler.root)
        end

        if options["name"]
          @default_spec = Specification.new do |s|
            s.name     = options["name"]
            s.source   = self
            s.version  = Gem::Version.new(options["version"])
            s.summary  = "Fake gemspec for #{options["name"]}"
            s.relative_loaded_from = "#{options["name"]}.gemspec"
          end
        end
      end

      def to_s
        "source code at #{@path}"
      end

      def load_spec_files
        index = Index.new

        if File.directory?(path)
          Dir["#{path}/#{@glob}"].each do |file|
            file = Pathname.new(file)
            # Eval the gemspec from its parent directory
            if spec = Dir.chdir(file.dirname) { eval(File.read(file.basename), binding, file.expand_path.to_s) }
              spec = Specification.from_gemspec(spec)
              spec.loaded_from = file.to_s
              spec.source = self
              index << spec
            end
          end

          index << default_spec if default_spec && index.empty?
        else
          raise PathError, "The path `#{path}` does not exist."
        end

        index
      end

      def local_specs
        @local_specs ||= load_spec_files
      end

      def install(spec)
        Bundler.ui.debug "  * Using path #{path}"
        generate_bin(spec)
      end

      alias specs local_specs

    private

      def generate_bin(spec)
        gem_dir  = spec.full_gem_path
        gem_file = nil # so we have access once after it's set in the block

        Dir.chdir(gem_dir) do
          gem_file = Gem::Builder.new(spec).build
        end

        installer = Gem::Installer.new File.join(gem_dir, gem_file),
          :bin_dir           => "#{Gem.dir}/bin",
          :wrappers          => true,
          :env_shebang       => false,
          :format_executable => false

        installer.instance_eval { @gem_dir = gem_dir }

        installer.build_extensions
        installer.generate_bin
      rescue Gem::InvalidSpecificationException => e
        Bundler.ui.warn "\n#{spec.name} at #{spec.full_gem_path} did not have a valid gemspec.\n" \
                        "This prevents bundler from installing bins or native extensions, but " \
                        "that may not affect its functionality."

        if !spec.extensions.empty? && !spec.email.empty?
          Bundler.ui.warn "If you need to use this package without installing it from a gem " \
                          "repository, please contact #{spec.email} and ask them " \
                          "to modify their .gemspec so it can work with `gem build`."
        end

        Bundler.ui.warn "The validation message from Rubygems was:\n  #{e.message}"
      end

    end

    class Git < Path
      attr_reader :uri, :ref, :options

      def initialize(options)
        super
        @uri  = options["uri"]
        @ref  = options["ref"] || options["branch"] || options["tag"] || 'master'
      end

      def to_s
        ref = @options["ref"] ? @options["ref"][0..6] : @ref
        "#{@uri} (at #{ref})"
      end

      def path
        Bundler.install_path.join("#{base_name}-#{uri_hash}-#{ref}")
      end

      def specs
        # Start by making sure the git cache is up to date
        cache
        checkout
        local_specs
      end

      def install(spec)
        Bundler.ui.debug "  * Using git #{uri}"

        if @installed
          Bundler.ui.debug "  * Already checked out revision: #{ref}"
        else
          Bundler.ui.debug "  * Checking out revision: #{ref}"
          checkout
          @installed = true
        end
        generate_bin(spec)
      end

      def lock
        @ref = @options["ref"] = revision
        checkout
      end

      def load_spec_files
        super
      rescue PathError
        raise PathError, "#{to_s} is not checked out. Please run `bundle install`"
      end

    private

      def git(command)
        out = %x{git #{command}}
        if $? != 0
          raise GitError, "An error has occurred in git. Cannot complete bundling."
        end
        out
      end

      def base_name
        File.basename(uri.sub(%r{^(\w+://)?([^/:]+:)},''), ".git")
      end

      def uri_hash
        if uri =~ %r{^\w+://(\w+@)?}
          # Downcase the domain component of the URI
          # and strip off a trailing slash, if one is present
          input = URI.parse(uri).normalize.to_s.sub(%r{/$},'')
        else
          # If there is no URI scheme, assume it is an ssh/git URI
          input = uri
        end
        Digest::SHA1.hexdigest(input)
      end

      def cache_path
        @cache_path ||= Bundler.cache.join("git", "#{base_name}-#{uri_hash}")
      end

      def cache
        if cache_path.exist?
          Bundler.ui.info "Updating #{uri}"
          in_cache { git %|fetch --quiet "#{uri}" master:master| }
        else
          Bundler.ui.info "Fetching #{uri}"
          FileUtils.mkdir_p(cache_path.dirname)
          git %|clone "#{uri}" "#{cache_path}" --bare --no-hardlinks|
        end
      end

      def checkout
        unless File.exist?(path.join(".git"))
          git %|clone --no-checkout "#{cache_path}" "#{path}"|
        end
        Dir.chdir(path) do
          git "fetch --quiet"
          git "reset --hard #{revision}"
        end
      end

      def revision
        @revision ||= in_cache { git("rev-parse #{ref}").strip }
      end

      def in_cache(&blk)
        Dir.chdir(cache_path, &blk)
      end
    end
  end
end
