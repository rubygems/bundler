module Bundler
  class DirectorySourceError < StandardError; end
  class GitSourceError < StandardError ; end
  # Represents a source of rubygems. Initially, this is only gem repositories, but
  # eventually, this will be git, svn, HTTP
  class Source
    attr_accessor :local
    attr_reader   :bundle

    def initialize(bundle, options)
      @bundle = bundle
    end

  private

    def process_source_gems(gems)
      new_gems = Hash.new { |h,k| h[k] = [] }
      gems.values.each do |spec|
        spec.source = self
        new_gems[spec.name] << spec
      end
      new_gems
    end
  end

  class GemSource < Source
    attr_reader :uri

    def initialize(bundle, options)
      super
      @uri = options[:uri]
      @uri = URI.parse(@uri) unless @uri.is_a?(URI)
      raise ArgumentError, "The source must be an absolute URI" unless @uri.absolute?
    end

    def can_be_local?
      false
    end

    def gems
      @specs ||= fetch_specs
    end

    def ==(other)
      uri == other.uri
    end

    def to_s
      @uri.to_s
    end

    class RubygemsRetardation < StandardError; end

    def download(spec)
      Bundler.logger.info "Downloading #{spec.full_name}.gem"

      destination = bundle.gem_path

      unless destination.writable?
        raise RubygemsRetardation, "destination: #{destination} is not writable"
      end

      # Download the gem
      Gem::RemoteFetcher.fetcher.download(spec, uri, destination)

      # Re-read the gemspec from the downloaded gem to correct
      # any errors that were present in the Rubyforge specification.
      new_spec = Gem::Format.from_file_by_path(destination.join('cache', "#{spec.full_name}.gem")).spec
      spec.__swap__(new_spec)
    end

  private

    def fetch_specs
      Bundler.logger.info "Updating source: #{to_s}"
      build_gem_index(fetch_main_specs + fetch_prerelease_specs)
    end

    def build_gem_index(index)
      gems = Hash.new { |h,k| h[k] = [] }
      index.each do |name, version, platform|
        spec = RemoteSpecification.new(name, version, platform, @uri)
        spec.source = self
        gems[spec.name] << spec if Gem::Platform.match(spec.platform)
      end
      gems
    end

    def fetch_main_specs
      Marshal.load(Gem::RemoteFetcher.fetcher.fetch_path("#{uri}/specs.4.8.gz"))
    rescue Gem::RemoteFetcher::FetchError => e
      raise ArgumentError, "#{to_s} is not a valid source: #{e.message}"
    end

    def fetch_prerelease_specs
      Marshal.load(Gem::RemoteFetcher.fetcher.fetch_path("#{uri}/prerelease_specs.4.8.gz"))
    rescue Gem::RemoteFetcher::FetchError
      Bundler.logger.warn "Source '#{uri}' does not support prerelease gems"
      []
    end
  end

  class SystemGemSource < Source

    def self.instance
      @instance
    end

    def self.new(*args)
      @instance ||= super
    end

    def initialize(bundle, options = {})
      super
      @source = Gem::SourceIndex.from_installed_gems
    end

    def can_be_local?
      false
    end

    def gems
      @gems ||= process_source_gems(@source.gems)
    end

    def ==(other)
      other.is_a?(SystemGemSource)
    end

    def to_s
      "system"
    end

    def download(spec)
      gemfile = Pathname.new(spec.loaded_from)
      gemfile = gemfile.dirname.join('..', 'cache', "#{spec.full_name}.gem")
      bundle.cache(gemfile)
    end

  private

  end

  class GemDirectorySource < Source
    attr_reader :location

    def initialize(bundle, options)
      super
      @location = options[:location]
    end

    def can_be_local?
      true
    end

    def gems
      @specs ||= fetch_specs
    end

    def ==(other)
      location == other.location
    end

    def to_s
      location.to_s
    end

    def download(spec)
      # raise NotImplementedError
    end

  private

    def fetch_specs
      specs = Hash.new { |h,k| h[k] = [] }

      Dir["#{@location}/*.gem"].each do |gemfile|
        spec = Gem::Format.from_file_by_path(gemfile).spec
        spec.source = self
        specs[spec.name] << spec
      end

      specs
    end
  end

  class DirectorySource < Source
    attr_reader :location, :specs, :required_specs

    def initialize(bundle, options)
      super
      if options[:location]
        @location = Pathname.new(options[:location]).expand_path
      end
      @glob           = options[:glob] || "**/*.gemspec"
      @specs          = {}
      @required_specs = []
    end

    def add_spec(path, name, version, require_paths = %w(lib))
      raise DirectorySourceError, "already have a gem defined for '#{path}'" if @specs[path.to_s]
      @specs[path.to_s] = Gem::Specification.new do |s|
        s.name     = name
        s.version  = Gem::Version.new(version)
      end
    end

    def can_be_local?
      true
    end

    def gems
      @gems ||= begin
        # Locate all gemspecs from the directory
        specs = locate_gemspecs
        specs = merge_defined_specs(specs)

        required_specs.each do |required|
          unless specs.any? {|k,v| v.name == required }
            raise DirectorySourceError, "No gemspec for '#{required}' was found in" \
              " '#{location}'. Please explicitly specify a version."
          end
        end

        process_source_gems(specs)
      end
    end

    def locate_gemspecs
      Dir["#{location}/#{@glob}"].inject({}) do |specs, file|
        file = Pathname.new(file)
        if spec = eval(File.read(file)) # and validate_gemspec(file.dirname, spec)
          spec.location = file.dirname.expand_path
          specs[spec.full_name] = spec
        end
        specs
      end
    end

    def merge_defined_specs(specs)
      @specs.each do |path, spec|
        # Set the spec location
        spec.location = "#{location}/#{path}"

        if existing = specs.values.find { |s| s.name == spec.name }
          if existing.version != spec.version
            raise DirectorySourceError, "The version you specified for #{spec.name}" \
              " is #{spec.version}. The gemspec is #{existing.version}."
          # Not sure if this is needed
          # ====
          # elsif File.expand_path(existing.location) != File.expand_path(spec.location)
          #   raise DirectorySourceError, "The location you specified for #{spec.name}" \
          #     " is '#{spec.location}'. The gemspec was found at '#{existing.location}'."
          end
        # elsif !validate_gemspec(spec.location, spec)
        #   raise "Your gem definition is not valid: #{spec}"
        else
          specs[spec.full_name] = spec
        end
      end
      specs
    end

    def validate_gemspec(path, spec)
      path = Pathname.new(path)
      msg  = "Gemspec for #{spec.name} (#{spec.version}) is invalid:"
      # Check the require_paths
      (spec.require_paths || []).each do |require_path|
        unless path.join(require_path).directory?
          Bundler.logger.warn "#{msg} Missing require path: '#{require_path}'"
          return false
        end
      end

      # Check the executables
      (spec.executables || []).each do |exec|
        unless path.join(spec.bindir, exec).file?
          Bundler.logger.warn "#{msg} Missing executable: '#{File.join(spec.bindir, exec)}'"
          return false
        end
      end

      true
    end

    def ==(other)
      # TMP HAX
      other.is_a?(DirectorySource)
    end

    def to_s
      "directory: '#{location}'"
    end

    def download(spec)
      # Nothing needed here
    end
  end

  class GitSource < DirectorySource
    attr_reader :ref, :uri, :branch

    def initialize(bundle, options)
      super
      @uri = options[:uri]
      @branch = options[:branch] || 'master'
      @ref = options[:ref] || "origin/#{@branch}"
    end

    def location
      # TMP HAX to get the *.gemspec reading to work
      bundle.gem_path.join('dirs', File.basename(@uri, '.git'))
    end

    def gems
      update
      checkout
      super
    end

    def download(spec)
      # Nothing needed here
    end

    def to_s
      "git: #{uri}"
    end

    private
      def update
        if location.directory?
          fetch
        else
          clone
        end
      end

      def fetch
        unless local
          Bundler.logger.info "Fetching git repository at: #{@uri}"
          Dir.chdir(location) { `git fetch origin` }
        end
      end

      def clone
        # Raise an error if the source should run in local mode,
        # but it has not been cached yet.
        if local
          raise SourceNotCached, "Git repository '#{@uri}' has not been cloned yet"
        end

        Bundler.logger.info "Cloning git repository at: #{@uri}"
        FileUtils.mkdir_p(location.dirname)
        `git clone #{@uri} #{location} --no-hardlinks`
      end

      def checkout
        Dir.chdir(location) { `git checkout --quiet #{@ref}` }
      end
  end
end
