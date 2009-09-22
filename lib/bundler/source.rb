module Bundler
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

      Gem::RemoteFetcher.fetcher.download(spec, uri, destination)
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

  private

    def fetch_specs

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
    attr_reader :location

    def initialize(options)
      @name          = options[:name]
      @version       = options[:version]
      @location      = options[:location]
      @require_paths = options[:require_paths] || %w(lib)
    end

    def can_be_local?
      true
    end

    def gems
      @gems ||= begin
        specs = {}

        # Find any gemspec files in the directory and load those specs
        Dir["#{location}/**/*.gemspec"].each do |file|
          file = Pathname.new(file)
          if spec = eval(File.read(file)) and validate_gemspec(file, spec)
            spec.location = file.dirname.expand_path
            specs[spec.full_name] = spec
          end
        end

        # If a gemspec for the dependency was not found, add it to the list
        if specs.keys.grep(/^#{Regexp.escape(@name)}/).empty?
          case
          when @version.nil?
            raise ArgumentError, "If you use :at, you must specify the gem " \
              "and version you wish to stand in for"
          when !Gem::Version.correct?(@version)
            raise ArgumentError, "If you use :at, you must specify a gem and " \
              "version. You specified #{@version} for the version"
          end

          default = Gem::Specification.new do |s|
            s.name     = @name
            s.version  = Gem::Version.new(@version) if @version
            s.location = location
          end
          specs[default.full_name] = default
        end

        specs
      end
    end

    # Too aggressive apparently.
    # ===
    # def validate_gemspec(file, spec)
    #   file = Pathname.new(file)
    #   Dir.chdir(file.dirname) do
    #     spec.validate
    #   end
    # rescue Gem::InvalidSpecificationException => e
    #   file = file.relative_path_from(repository.path)
    #   Bundler.logger.warn e.message
    #   Bundler.logger.warn "Gemspec #{spec.name} (#{spec.version}) found at '#{file}' is not valid"
    #   false
    # end
    def validate_gemspec(file, spec)
      base = file.dirname
      msg  = "Gemspec for #{spec.name} (#{spec.version}) is invalid:"
      # Check the require_paths
      (spec.require_paths || []).each do |path|
        unless base.join(path).directory?
          Bundler.logger.warn "#{msg} Missing require path: '#{path}'"
          return false
        end
      end

      # Check the executables
      (spec.executables || []).each do |exec|
        unless base.join(spec.bindir, exec).file?
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
