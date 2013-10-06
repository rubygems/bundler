require 'bundler/rubygems_integration'

module Bundler
  class MarshalledSpecs

    def initialize(source, remote_uri, fetcher)
      @source, @remote_uri = source, remote_uri
      @fetcher = fetcher
    end

    def specs_index
      @specs_index ||= generate_index
    end
    alias_method :specs, :specs_index

  private

    def generate_index
      Index.build do |index|
        fetch_all_remote_specs.each do |name, version, platform|
          next if name == 'bundler'
          spec = RemoteSpecification.new(name, version, platform, @fetcher)
          spec.source = @source
          spec.source_uri = @remote_uri
          index << spec
        end
      end
    end

    # fetch from modern index: specs.4.8.gz
    def fetch_all_remote_specs
      old_sources = Bundler.rubygems.sources
      Bundler.rubygems.sources = ["#{@remote_uri}"]
      Bundler::Retry.new("source fetch").attempts do
        Bundler.rubygems.fetch_all_remote_specs[@remote_uri]
      end
    rescue Gem::RemoteFetcher::FetchError, OpenSSL::SSL::SSLError => e
      if e.message.match("certificate verify failed")
        raise Fetcher::CertificateFailureError.new(uri)
      else
        Bundler.ui.trace e
        raise HTTPError, "Could not fetch specs from #{uri}"
      end
    ensure
      Bundler.rubygems.sources = old_sources
    end

  end
end