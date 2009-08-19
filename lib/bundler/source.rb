module Bundler
  # Represents a source of rubygems. Initially, this is only gem repositories, but
  # eventually, this will be git, svn, HTTP
  class Source
    attr_reader :uri

    def initialize(options)
      @uri = options[:uri]
      @uri = URI.parse(@uri) unless @uri.is_a?(URI)
      raise ArgumentError, "The source must be an absolute URI" unless @uri.absolute?
    end

    def specs
      @specs ||= fetch_specs
    end

    def ==(other)
      uri == other.uri
    end

    def to_s
      @uri.to_s
    end

    def download(spec, destination)
      Bundler.logger.info "Downloading #{spec.full_name}.gem"
      Gem::RemoteFetcher.fetcher.download(spec, uri, destination)
    end

  private

    def fetch_specs
      Bundler.logger.info "Updating source: #{to_s}"

      deflated = Gem::RemoteFetcher.fetcher.fetch_path("#{uri}/Marshal.4.8.Z")
      inflated = Gem.inflate deflated

      index = Marshal.load(inflated)
      specs = Hash.new { |h,k| h[k] = {} }

      index.gems.values.each do |spec|
        next unless Gem::Platform.match(spec.platform)
        spec.source = self
        specs[spec.name][spec.version] = spec
      end

      specs
    rescue Gem::RemoteFetcher::FetchError => e
      raise ArgumentError, "#{to_s} is not a valid source: #{e.message}"
    end
  end

  # HAX
  class DirectoryGemSpecification < Gem::Specification
    attr_accessor :location

    def full_gem_path
      @location
    end
  end

  class DirectorySource
    def initialize(options)
      @name          = options[:name]
      @version       = options[:version]
      @location      = options[:location]
      @require_paths = options[:require_paths] || %w(lib)
    end
    
    def specs
      @specs ||= begin
        [DirectoryGemSpecification.new do |s|
          s.name          = @name
          s.version       = @version
          s.location      = @location
          s.require_paths = [@require_paths].flatten
        end]
      end
    end

    def ==(other)
      # TMP HAX
      other.is_a?(DirectorySource)
    end

    def to_s
      "#{@name} (#{@version}) Located at: '#{@location}'"
    end

    def download(spec, destination)
      # NO-OP
    end
  end
end