module Bundler
  # Represents a source of rubygems. Initially, this is only gem repositories, but
  # eventually, this will be git, svn, HTTP
  class Source
    attr_accessor :repository
  end

  class GemSource < Source
    attr_reader :uri

    def initialize(options)
      @uri = options[:uri]
      @uri = URI.parse(@uri) unless @uri.is_a?(URI)
      raise ArgumentError, "The source must be an absolute URI" unless @uri.absolute?
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
      prerelease_index = fetcher.fetch_path("#{uri}/prerelease_specs.4.8.gz")
      index = Marshal.load(main_index) + Marshal.load(prerelease_index)

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

  class GemDirectorySource < Source
    attr_reader :location

    def initialize(options)
      @location = options[:location]
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

    def gems
      @gems ||= begin
        specs = {}

        # Find any gemspec files in the directory and load those specs
        Dir["#{location}/**/*.gemspec"].each do |file|
          spec = eval(File.read(file))
          spec.location = Pathname.new(file).dirname.expand_path
          specs[spec.full_name] = spec
        end

        # If a gemspec for the dependency was not found, add it to the list
        if specs.keys.grep(/^#{Regexp.escape(@name)}/).empty?
          case
          when @version.nil?
            raise ArgumentError, "If you use :at, you must specify the gem" \
              "and version you wish to stand in for"
          when !Gem::Version.correct?(@version)
            raise ArgumentError, "If you use :at, you must specify a gem and" \
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

    def ==(other)
      # TMP HAX
      other.is_a?(DirectorySource)
    end

    def to_s
      "#{@name} (#{@version}) Located at: '#{location}'"
    end

    def download(spec)
      # repository.download_path_for(:gem)
      # FileUtils.mkdir_p(repository.download_path_for(:gem).join("gems"))
      # File.symlink(
      #   @location.join(spec.location),
      #   repository.download_path_for(:gem).join("gems", spec.full_name)
      # )
      # repository.add_spec(spec)

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
      if location.directory?
        Bundler.logger.info "Git repository #{@uri} has already been cloned"
      else
        FileUtils.mkdir_p(location)

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
      # dest = repository.download_path_for(:directory).join(@name)
      # repository.add_spec(spec)
      # FileUtils.mkdir_p(repository.download_path_for(:gem).join("gems"))
      # File.symlink(
      #   dest.join(spec.location),
      #   repository.download_path_for(:gem).join("gems", spec.full_name)
      # )
      # # TMPHAX
      # if spec.name == @name && !dest.directory?
      #   FileUtils.mkdir_p(dest.dirname)
      #   FileUtils.mv(tmp_path.join("gitz", spec.name), dest)
      # end
    end
  end
end
