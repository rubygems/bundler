require "rubygems/remote_fetcher"
require "rubygems/format"
require "digest/sha1"
require "open3"

module Bundler
  module Source
    class Rubygems
      attr_reader :uri, :options

      def initialize(options = {})
        @options = options
        @uri = options["uri"]
        @uri = URI.parse(@uri) unless @uri.is_a?(URI)
        raise ArgumentError, "The source must be an absolute URI" unless @uri.absolute?
      end

      def to_s
        "rubygems repository at #{uri}"
      end

      def specs
        @specs ||= fetch_specs
      end

      def install(spec)
        destination = Gem.dir

        Bundler.ui.debug "  * Downloading"
        gem_path  = Gem::RemoteFetcher.fetcher.download(spec, uri, destination)
        Bundler.ui.debug "  * Installing"
        installer = Gem::Installer.new gem_path,
          :install_dir         => Gem.dir,
          :ignore_dependencies => true,
          :wrappers            => true,
          :env_shebang         => true,
          :bin_dir             => "#{Gem.dir}/bin"

        installer.install
      end

    private

      def fetch_specs
        index = Index.new
        Bundler.ui.info "Fetching source index from #{uri}"
        (main_specs + prerelease_specs).each do |name, version, platform|
          next unless Gem::Platform.match(platform)
          spec = RemoteSpecification.new(name, version, platform, @uri)
          spec.source = self
          index << spec
        end
        index.freeze
      end

      def main_specs
        Marshal.load(Gem::RemoteFetcher.fetcher.fetch_path("#{uri}/specs.4.8.gz"))
      rescue Gem::RemoteFetcher::FetchError => e
        raise ArgumentError, "#{to_s} is not a valid source: #{e.message}"
      end

      def prerelease_specs
        Marshal.load(Gem::RemoteFetcher.fetcher.fetch_path("#{uri}/prerelease_specs.4.8.gz"))
      rescue Gem::RemoteFetcher::FetchError
        Bundler.ui.warn "Source '#{uri}' does not support prerelease gems"
        []
      end
    end

    class SystemGems
      def specs
        @specs ||= begin
          index = Index.new

          Gem::SourceIndex.from_installed_gems.each do |name, spec|
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

          index.freeze
        end
      end

      def install(spec)
        destination = Gem.dir

        Bundler.ui.debug "  * Installing from pack"
        installer = Gem::Installer.new "#{@path}/#{spec.full_name}.gem",
          :install_dir         => Gem.dir,
          :ignore_dependencies => true,
          :wrappers            => true,
          :env_shebang         => true,
          :bin_dir             => "#{Gem.dir}/bin"

        installer.install
      end
    end

    class Path
      attr_reader :path, :options

      def initialize(options)
        @options = options
        @glob = options["glob"] || "{,*/}*.gemspec"
        @path = options["path"]
        @default_spec = nil
      end

      def to_s
        "source code at #{@path}"
      end

      def default_spec(*args)
        return @default_spec if args.empty?
        name, version = *args
        @default_spec = Specification.new do |s|
          s.name     = name
          s.source   = self
          s.version  = Gem::Version.new(version)
          s.relative_loaded_from = "#{name}.gemspec"
        end
      end

      def local_specs
        @local_specs ||= begin
          index = Index.new

          if File.directory?(path)
            Dir["#{path}/#{@glob}"].each do |file|
              file = Pathname.new(file)
              relative_path = file.relative_path_from(Pathname.new(path))
              # Do it in the root of the repo in case they do
              # assume being in the root
              if spec = Dir.chdir(path) { eval(File.read(relative_path)) }
                spec = Specification.from_gemspec(spec)
                spec.loaded_from = file
                spec.source      = self
                index << spec
              end
            end

            index << default_spec if default_spec && index.empty?
          end

          index.freeze
        end
      end

      def install(spec)
        Bundler.ui.debug "  * Using path #{path}"
        generate_bin(spec)
      end

      alias specs local_specs

    private

      def generate_bin(spec)
        # HAX -- Generate the bin
        bin_dir = "#{Gem.dir}/bin"
        gem_dir = spec.full_gem_path
        installer = Gem::Installer.allocate
        installer.instance_eval do
          @spec     = spec
          @bin_dir  = bin_dir
          @gem_dir  = gem_dir
          @wrappers = true
          @env_shebang = false
          @format_executable = false
        end
        installer.generate_bin
      end

    end

    class Git < Path
      attr_reader :uri, :ref, :options

      def initialize(options)
        @options = options
        @glob = options["glob"] || "{,*/}*.gemspec"
        @uri  = options["uri"]
        @ref  = options["ref"] || options["branch"] || 'master'
      end

      def to_s
        ref = @options["ref"] ? @options["ref"][0..6] : @ref
        "#{@uri} (at #{ref})"
      end

      def path
        Bundler.install_path.join("#{base_name}-#{uri_hash}-#{ref}")
      end

      def specs
        @specs ||= begin
          index = Index.new
          # Start by making sure the git cache is up to date
          cache
          # Find all gemspecs in the repo
          in_cache do
            out   = %x(git ls-tree -r #{revision}).strip
            lines = out.split("\n").select { |l| l =~ /\.gemspec$/ }
            # Loop over the lines and extract the relative path and the
            # git hash
            lines.each do |line|
              next unless line =~ %r{^(\d+) (blob|tree) ([a-zf0-9]+)\t(.*)$}
              hash, file = $3, $4
              # Read the gemspec
              if spec = eval(%x(git cat-file blob #{$3}))
                spec = Specification.from_gemspec(spec)
                spec.relative_loaded_from = file
                spec.source = self
                index << spec
              end
            end
          end

          index << default_spec if default_spec && index.empty?

          index.freeze
        end
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

    private

      def git(command)
        out = %x{git #{command}}
        if $? != 0
          raise GitError, "An error has occurred in git. Cannot complete bundling."
        end
        out
      end

      def base_name
        File.basename(uri, ".git")
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
          in_cache { git "fetch --quiet #{uri} master:master" }
        else
          Bundler.ui.info "Fetching #{uri}"
          FileUtils.mkdir_p(cache_path.dirname)
          git "clone #{uri} #{cache_path} --bare --no-hardlinks"
        end
      end

      def checkout
        unless File.exist?("#{path}/.git")
          %x(git clone --no-checkout #{cache_path} #{path})
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
