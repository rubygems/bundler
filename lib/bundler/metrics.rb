# frozen_string_literal: true

require "time"
require "securerandom"
require "digest"
module Bundler
  class Metrics
    attr_accessor :metrics_hash, :path

    def initialize
      @path = Pathname.new(File.join(Bundler.user_home.join(".bundle"), "metrics.yml"))
      add_metrics
    end

    # sending user agent metrics over http
    def add_metrics
      @metrics_hash = Hash.new
      @metrics_hash["time_stamp"] = Time.now.utc.iso8601
      # add a random ID so we can consolidate runs server-side
      @metrics_hash["request_id"] = SecureRandom.hex(8)
      # hash the origin repository to calculate unique bundler users
      origin = `git remote get-url origin`
      @metrics_hash["origin"] = Digest::MD5.hexdigest(origin.chomp) unless origin.empty?
      @metrics_hash["command"] = ARGV.first
      ruby = Bundler::RubyVersion.system
      @metrics_hash["host"] = ruby.host
      @metrics_hash["ruby_version"] = ruby.versions_string(ruby.versions)
      @metrics_hash["bundler_version"] = Bundler::VERSION
      @metrics_hash["rubygems_version"] = Gem::VERSION
      if ruby.engine != "ruby"
        # engine_version raises on unknown engines
        engine_version = begin
                            ruby.engine_versions
                          rescue RuntimeError
                            "???"
                          end
        @metrics_hash["ruby_engine"] = "#{ruby.engine}/#{ruby.versions_string(engine_version)}"
      end
      options = Bundler.settings.all.join(",")
      @metrics_hash["options"] = options unless options.empty?
      @metrics_hash["ci"] = cis.join(",") if cis.any?
      # add any user agent strings set in the config
      extra_ua = Bundler.settings[:user_agent]
      @metrics_hash["extra_ua"] = extra_ua if extra_ua
      add_additional_metrics
      write_to_file
    end

    def send_metrics
      # dummy server for now
      uri = URI.parse("https://webhook.site/ee1e4493-c0f0-4e40-84fb-3a36d79d47fb")
      http = Net::HTTP.new(uri.host, uri.port)
      http.use_ssl = true
      request = Net::HTTP::Post.new(uri.request_uri)
      request.set_form_data(read_from_file)
      http.request(request)
      # We've sent the metrics so we empty the file
      # File::TRUNC is preferable since File.truncate doesn't work for all systems
      open(@path, File::TRUNC) if File.exist?(@path)
    end

  private

    def write_to_file
      SharedHelpers.filesystem_access(@path) do |file|
        FileUtils.mkdir_p(file.dirname) unless File.exist?(file)
        require_relative "yaml_serializer"
        File.open(file, "a") {|f| f.write(YAMLSerializer.dump(@metrics_hash)) }
      end
    end

    def read_from_file
      valid_file = @path.exist? && !@path.size.zero?
      return {} unless valid_file
      list = Array.new
      SharedHelpers.filesystem_access(@path, :read) do |file|
        Psych.load_stream(file.read) {|doc| list << doc }
      end
      list
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

    def add_additional_metrics
      case ARGV.first
      when "install"
        @metrics_hash["gemfile_gem_count"] = Bundler.definition.dependencies.count
        @metrics_hash["installed_gem_count"] = Bundler.definition.specs.count
        @metrics_hash["git_gem_count"] = Bundler.definition.sources.git_sources.count
        @metrics_hash["path_gem_count"] = Bundler.definition.sources.path_sources.count
        # The last index of rubygems_sources is an entry of all sources concatenated, so it has to be ignored
        @metrics_hash["rubygems_source_count"] = Bundler.definition.sources.rubygems_sources[0..-2].count
        @metrics_hash["gem_sources"] = Bundler.definition.sources.rubygems_sources[0..-2].map {|s| Digest::MD5.hexdigest(s.get_source) } if @metrics_hash["rubygems_source_count"] > 1
        # The last index is the only entry if there's a single source, so iteration has to be different
        @metrics_hash["gem_sources"] = Bundler.definition.sources.rubygems_sources.map {|s| Digest::MD5.hexdigest(s.get_source) } if @metrics_hash["rubygems_source_count"] == 1
      when "exec"
        ARGV[1..-1].each_index {|i| @metrics_hash["executed_command_#{i+1}"] = ARGV[i+1] }
      end
    end
  end
end
