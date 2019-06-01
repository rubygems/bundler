module Bundler
  class Fetcher
    class Metrics

      attr_accessor :metrics_hash, :path

      def initialize
        # dummy server for now
        uri = URI.parse("https://webhook.site/ee1e4493-c0f0-4e40-84fb-3a36d79d47fb")
        @http = Net::HTTP.new(uri.host, uri.port)
        @http.use_ssl = true
        @request = Net::HTTP::Post.new(uri.request_uri)
        @metrics_hash = Hash.new
        @path = Pathname.new(File.expand_path("~/.bundle/metrics.yml"))
      end

      def write_to_file
        SharedHelpers.filesystem_access(@path) do |file|
          FileUtils.mkdir_p(file.dirname) unless File.exist?(file)
          require_relative "../yaml_serializer"
          File.open(file, "w") {|f| f.write(YAMLSerializer.dump(@metrics_hash)) }
        end
      end

      def read_from_file
        valid_file = @path.exist? && !@path.size.zero?
        return {} unless valid_file
        SharedHelpers.filesystem_access(@path, :read) do |file|
          require_relative "../yaml_serializer"
          YAMLSerializer.load file.read
        end
      end

      def cis
        env_cis = {
          "TRAVIS" => "travis",
          "CIRCLECI" => "circle",
          "SEMAPHORE" => "semaphore",
          "JENKINS_URL" => "jenkins",
          "BUILDBOX" => "buildbox",
          "GO_SERVER_URL" => "go",
          "SNAP_CI" => "snap",
          "CI_NAME" => ENV["CI_NAME"],
          "CI" => "ci",
        }
        env_cis.find_all {|env, _| ENV[env] }.map {|_, ci| ci }
      end

      # sending user agent metrics over http
      def add_metrics
        ruby = Bundler::RubyVersion.system
        @metrics_hash["Bundler Version"] = "bundler/#{Bundler::VERSION}"
        @metrics_hash["Rubygems Version"] = "rubygems/#{Gem::VERSION}"
        @metrics_hash["Ruby Versions"] = "ruby/#{ruby.versions_string(ruby.versions)}"
        @metrics_hash["Roby Host"] = "(#{ruby.host})"
        @metrics_hash["Command"] = "command/#{ARGV.first}"
        if ruby.engine != "ruby"
          # engine_version raises on unknown engines
          engine_version = begin
                             ruby.engine_versions
                           rescue RuntimeError
                             "???"
                           end
          @metrics_hash["Ruby Engine"] = "#{ruby.engine}/#{ruby.versions_string(engine_version)}"
        end
        @metrics_hash["Options"] = "options/#{Bundler.settings.all.join(",")}"
        @metrics_hash["CI"] = "ci/#{cis.join(",")}" if cis.any?
        # add a random ID so we can consolidate runs server-side
        @metrics_hash["Request ID"] = SecureRandom.hex(8)
        # add any user agent strings set in the config
        extra_ua = Bundler.settings[:user_agent]
        @metrics_hash["Extra UA in config"] = extra_ua if extra_ua
        write_to_file
      end

      def send_metrics
        read_from_file
        @request.set_form_data(@metrics_hash)
        @http.request(@request)
      end
    end
  end
end
