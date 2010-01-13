require "rubygems/remote_fetcher"
require "digest/sha1"

module Bubble
  module Source
    class Rubygems
      attr_reader :uri

      def initialize(options = {})
        @uri = options[:uri]
        @uri = URI.parse(@uri) unless @uri.is_a?(URI)
        raise ArgumentError, "The source must be an absolute URI" unless @uri.absolute?
      end

      def specs
        @specs ||= fetch_specs
      end

      def local_specs
        Index.from_installed_gems
      end

      def install(spec)
        inst = Gem::DependencyInstaller.new(:ignore_dependencies => true)
        inst.install spec.name, spec.version
      end

    private

      def fetch_specs
        index = Index.new
        (main_specs + prerelease_specs).each do |name, version, platform|
          spec = RemoteSpecification.new(name, version, platform, @uri)
          spec.source = self
          index << spec
        end
        index
      end

      def main_specs
        Marshal.load(Gem::RemoteFetcher.fetcher.fetch_path("#{uri}/specs.4.8.gz"))
      rescue Gem::RemoteFetcher::FetchError => e
        raise ArgumentError, "#{to_s} is not a valid source: #{e.message}"
      end

      def prerelease_specs
        Marshal.load(Gem::RemoteFetcher.fetcher.fetch_path("#{uri}/prerelease_specs.4.8.gz"))
      rescue Gem::RemoteFetcher::FetchError
        Bundler.logger.warn "Source '#{uri}' does not support prerelease gems"
        []
      end
    end

    class Path
      attr_reader :path

      def initialize(options)
        @glob = options[:glob] || "{,*/}*.gemspec"
        @path = options[:path]
      end

      def specs
        @specs ||= begin
          index = Index.new

          Dir["#{path}/#{@glob}"].each do |file|
            file = Pathname.new(file)
            if spec = eval(File.read(file))
              spec.location = file.dirname.expand_path
              index << spec
            end
          end
          index
        end
      end

      def install(spec)
      end
    end

    class Git < Path
      def initialize(options)
        @uri = options[:uri]
        sha = Digest::SHA1.hexdigest(URI.parse(@uri).normalize.to_s.sub(%r{/$}, ''))
        @location = Bubble.cache.join("git", "#{File.basename(@uri, ".git")}-#{sha}")
        @branch   = options[:branch] || 'master'
        @ref      = options[:ref] || "origin/#{@branch}"
      end

      def specs
        FileUtils.mkdir_p(@location.dirname)
        `git clone #{@uri} #{@location} --bare --no-hardlinks`
      end
    end
  end
end