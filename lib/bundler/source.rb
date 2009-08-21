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

  class DirectorySource
    def initialize(options)
      @name          = options[:name]
      @version       = options[:version]
      @location      = options[:location]
      @require_paths = options[:require_paths] || %w(lib)
    end

    def specs
      @specs ||= begin
        spec = Gem::Specification.new do |s|
          s.name          = @name
          s.version       = Gem::Version.new(@version)
          s.require_paths = Array(@require_paths).map {|p| File.join(@location, p) }
          s.source        = self
        end
        { spec.name => { spec.version => spec } }
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
      destination = repository.download_path_for(:directory).join('specifications')
      destination.mkdir unless destination.exist?

      File.open(destination.join("#{spec.full_name}.gemspec"), 'w') do |f|
        f.puts spec.to_ruby
      end
    end
  end
end