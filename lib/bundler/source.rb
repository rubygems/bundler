module Bundler
  # Represents a source of rubygems. Initially, this is only gem repositories, but
  # eventually, this will be git, svn, HTTP
  class Source
    attr_accessor :tmp_path
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

    def download(spec, repository)
      Bundler.logger.info "Downloading #{spec.full_name}.gem"

      destination = repository.download_path_for(:gem)

      unless destination.writable?
        raise RubygemsRetardation
      end

      Gem::RemoteFetcher.fetcher.download(spec, uri, repository.download_path_for(:gem))
    end

  private

    def fetch_specs
      Bundler.logger.info "Updating source: #{to_s}"

      deflated = Gem::RemoteFetcher.fetcher.fetch_path("#{uri}/Marshal.4.8.Z")
      inflated = Gem.inflate deflated

      index = Marshal.load(inflated)
      index.gems
    rescue Gem::RemoteFetcher::FetchError => e
      raise ArgumentError, "#{to_s} is not a valid source: #{e.message}"
    end
  end

  class DirectorySource < Source
    def initialize(options)
      @name          = options[:name]
      @version       = options[:version]
      @location      = options[:location]
      @require_paths = options[:require_paths] || %w(lib)
    end

    def gems
      @gems ||= begin
        spec = Gem::Specification.new do |s|
          s.name          = @name
          s.version       = Gem::Version.new(@version)
          # s.require_paths = Array(@require_paths).map {|p| File.join(@location, p) }
        end
        { spec.full_name => spec }
      end
    end

    def ==(other)
      # TMP HAX
      other.is_a?(DirectorySource)
    end

    def to_s
      "#{@name} (#{@version}) Located at: '#{@location}'"
    end

    def download(spec, repository)
      spec.require_paths.map! { |p| File.join(@location, p) }
      repository.add_spec(:directory, spec)
    end
  end

  class GitSource < DirectorySource
    def initialize(options)
      super
      @uri = options[:uri]
    end

    def gems
      specs = super
      spec  = specs.values.first

      FileUtils.mkdir_p(tmp_path.join("gitz"))
      Bundler.logger.info "Cloning git repository at: #{@uri}"
      `git clone #{@uri} #{tmp_path.join("gitz", spec.name)}`

      specs
    end

    def download(spec, repository)
      dest = repository.download_path_for(:directory).join(spec.name)
      spec.require_paths.map! { |p| File.join(dest, p) }
      repository.add_spec(:directory, spec)
      FileUtils.mkdir_p(dest.dirname)
      FileUtils.mv(tmp_path.join("gitz", spec.name), dest)
    end
  end
end