module Bundler
  class Fetcher
    class Metrics

      def initialize
        #dummy server for now
        uri = URI.parse("https://webhook.site/6e4832e5-df36-422d-ae2f-53c4e85ab475")
        @http = Net::HTTP.new(uri.host, uri.port)
        @http.use_ssl = true
        @request = Net::HTTP::Post.new(uri.request_uri)
        @metrics = Hash.new
      end

      #sending user agent metrics over http
      def add_metrics(cis)
        puts "SENDING METRICS"
        ruby = Bundler::RubyVersion.system
        @metrics["Request ID"] = SecureRandom.hex(8)
        @metrics["Bundler Version"] = "bundler/#{Bundler::VERSION}"
        @metrics["Rubygems Version"] = "rubygems/#{Gem::VERSION}"
        @metrics["Ruby Versions"] = "ruby/#{ruby.versions_string(ruby.versions)}"
        @metrics["Roby Host"] = "(#{ruby.host})"
        @metrics["Command"] = "command/#{ARGV.first}"
        if ruby.engine != "ruby"
          # engine_version raises on unknown engines
          engine_version = begin
                             ruby.engine_versions
                           rescue RuntimeError
                             "???"
                           end
          @metrics["Ruby Engine"] = "#{ruby.engine}/#{ruby.versions_string(engine_version)}"
        end
        @metrics["Options"] = "options/#{Bundler.settings.all.join(",")}"
        @metrics["ci"] = "ci/#{cis.join(",")}" if cis.any?
        extra_ua = Bundler.settings[:user_agent]
        @metrics["Extra UA strings set in config"] = extra_ua if extra_ua
        @request.set_form_data(@metrics)
        @http.request(@request)
        puts "METRICS SENT"
      end
    end
  end
end