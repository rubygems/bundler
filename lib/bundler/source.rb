module Bundler
  class DirectorySourceError < StandardError; end
  class GitSourceError < StandardError ; end
  # Represents a source of rubygems. Initially, this is only gem repositories, but
  # eventually, this will be git, svn, HTTP
  class Source
    attr_accessor :repository, :local
  end

  class GemSource < Source
    attr_reader :uri

    def initialize(options)
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

      destination = repository.path

      unless destination.writable?
        raise RubygemsRetardation
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

      fetcher = Gem::RemoteFetcher.fetcher
      main_index = fetcher.fetch_path("#{uri}/specs.4.8.gz")
      begin
        prerelease_index = fetcher.fetch_path("#{uri}/prerelease_specs.4.8.gz")
        index = Marshal.load(main_index) + Marshal.load(prerelease_index)
      rescue Gem::RemoteFetcher::FetchError
        Bundler.logger.warn "Source '#{uri}' does not support prerelease gems"
        index = Marshal.load(main_index)
      end

      gems = {}
      index.each do |name, version, platform|
        spec = RemoteSpecification.new(name, version, platform, @uri)
        gems[spec.full_name] = spec
      end
      gems
    rescue Gem::RemoteFetcher::FetchError => e
      raise ArgumentError, "#{to_s} is not a valid source: #{e.message}"
    end
  end

  class SystemGemSource < Source
    def initialize(options)
      # Nothing to do
    end

    def can_be_local?
      false
    end

    def gems
      @specs ||= Gem::SourceIndex.from_installed_gems.gems
    end

    def ==(other)
      other.is_a?(SystemGemSource)
    end

    def to_s
      "system"
    end

    def download(spec)
      # gemfile = Pathname.new(local.loaded_from)
      # gemfile = gemfile.dirname.join('..', 'cache', "#{local.full_name}.gem").expand_path
      # repository.cache(File.join(Gem.dir, "cache", "#{local.full_name}.gem"))
      gemfile = Pathname.new(spec.loaded_from)
      gemfile = gemfile.dirname.join('..', 'cache', "#{spec.full_name}.gem")
      repository.cache(gemfile)
    end

  end

  class GemDirectorySource < Source
    attr_reader :location

    def initialize(options)
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
      specs = {}

      Dir["#{@location}/*.gem"].each do |gemfile|
        spec = Gem::Format.from_file_by_path(gemfile).spec
        specs[spec.full_name] = spec
      end

      specs
    end
  end

  class DirectorySource < Source
    attr_reader :location, :specs, :required_specs

    def initialize(options)
      @location       = Pathname.new(options[:location]).expand_path if options[:location]
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

        specs
      end
    end

    def locate_gemspecs
      Dir["#{location}/**/*.gemspec"].inject({}) do |specs, file|
        file = Pathname.new(file)
        if spec = eval(File.read(file)) and validate_gemspec(file.dirname, spec)
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
        elsif !validate_gemspec(spec.location, spec)
          raise "Your gem definition is not valid: #{spec}"
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
      "#{@name} (#{@version}) Located at: '#{location}'"
    end

    def download(spec)
      # Nothing needed here
    end
  end

  class GitSource < DirectorySource
    attr_reader :ref, :uri, :branch

    def initialize(options)
      super
      @uri = options[:uri]
      @ref = options[:ref]
      @branch = options[:branch]
    end

    def location
      # TMP HAX to get the *.gemspec reading to work
      repository.path.join('dirs', File.basename(@uri, '.git'))
    end

    def gems
      unless location.directory?
        # Raise an error if the source should run in local mode,
        # but it has not been cached yet.
        if local
          raise SourceNotCached, "Git repository '#{@uri}' has not been cloned yet"
        end

        FileUtils.mkdir_p(location.dirname)

        Bundler.logger.info "Cloning git repository at: #{@uri}"
        `git clone #{@uri} #{location} --no-hardlinks`

        if @ref
          Dir.chdir(location) { `git checkout #{@ref}` }
        elsif @branch && @branch != "master"
          Dir.chdir(location) { `git checkout origin/#{@branch}` }
        end
      end
      super
    end

    def download(spec)
      # Nothing needed here
    end
  end
end
