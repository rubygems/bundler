# frozen_string_literal: true

require "time"
require "securerandom"
require "digest"

module Bundler
  class Metrics
    attr_reader :system_metrics, :path

    def initialize
      @path = Bundler.user_bundle_path("metrics")
      @standalone_metrics = Array.new
    end

    def record(entry = {})
      entry["timestamp"] = Time.now.utc.iso8601
      @standalone_metrics << entry
      write_to_file
    end

    # sending user agent metrics over http
    # to be called when bundle install or bundle outdated is run
    def record_system_info
      @system_metrics = Hash.new
      @system_metrics["timestamp"] = Time.now.utc.iso8601
      # add a random ID so we can consolidate runs server-side
      @system_metrics["request_id"] = SecureRandom.hex(8)
      # hash the origin repository to calculate unique bundler users
      begin
        origin = `git remote get-url origin`
        @system_metrics["origin"] = Digest::MD5.hexdigest(origin.chomp) unless origin.empty?
      rescue Errno::ENOENT
      end
      begin
        git_ver = `git --version`
        @system_metrics["git_version"] = git_ver[git_ver.index(/\d/)..git_ver.rindex(/\d/)] unless git_ver.empty?
      rescue Errno::ENOENT
      end
      begin
        rvm_ver = `rvm --version`
        @system_metrics["rvm_version"] = rvm_ver[rvm_ver.index(/\d/)..-1].chomp unless rvm_ver.empty?
      rescue Errno::ENOENT
      end
      begin
        rbenv_ver = `rbenv --version`
        @system_metrics["rbenv_version"] = rbenv_ver[rbenv_ver.index(/\d/)..-1].chomp unless rbenv_ver.empty?
      rescue Errno::ENOENT
      end
      @system_metrics["command"] = ARGV.first
      ruby = Bundler::RubyVersion.system
      @system_metrics["host"] = ruby.host
      @system_metrics["ruby_version"] = ruby.versions_string(ruby.versions)
      @system_metrics["bundler_version"] = Bundler::VERSION
      @system_metrics["rubygems_version"] = Gem::VERSION
      if ruby.engine != "ruby"
        # engine_version raises on unknown engines
        engine_version = begin
                            ruby.engine_versions
                          rescue RuntimeError
                            "???"
                          end
        @system_metrics["ruby_engine"] = "#{ruby.engine}/#{ruby.versions_string(engine_version)}"
      end
      options = Bundler.settings.all.join(",")
      @system_metrics["options"] = options unless options.empty?
      @system_metrics["ci"] = cis.join(",") if cis.any?
      # add any user agent strings set in the config
      extra_ua = Bundler.settings[:user_agent]
      @system_metrics["extra_ua"] = extra_ua if extra_ua
    end

    def send_metrics
      # dummy server for now
      begin
        uri = URI.parse("https://webhook.site/ee1e4493-c0f0-4e40-84fb-3a36d79d47fb")
        http = Net::HTTP.new(uri.host, uri.port)
        http.use_ssl = true
        request = Net::HTTP::Post.new(uri.request_uri)
        request.set_form_data(read_from_file)
        http.request(request)
      rescue SocketError
        "TCP connection failed"
      end
      # We've sent the metrics so we empty the file
      # File::TRUNC is preferable since File.truncate doesn't work for all systems
      open(@path, File::TRUNC) if File.exist?(@path)
    end

    def record_install_info
      @system_metrics["gemfile_gem_count"] = Bundler.definition.dependencies.count
      @system_metrics["installed_gem_count"] = Bundler.definition.specs.count
      @system_metrics["git_gem_count"] = Bundler.definition.sources.git_sources.count
      @system_metrics["path_gem_count"] = Bundler.definition.sources.path_sources.count
      @system_metrics["rubygems_source_count"] = Bundler.definition.sources.rubygems_sources.count
      @system_metrics["gem_sources"] = Bundler.definition.sources.rubygems_sources.map {|s| Digest::MD5.hexdigest(s.get_source) }
    end

  private

    def write_to_file
      SharedHelpers.filesystem_access(@path) do |file|
        FileUtils.mkdir_p(file.dirname) unless File.exist?(file)
        require "psych"
        File.open(file, "a") {|f| f.write(Psych.dump(@standalone_metrics)) }
      end
    end

    def read_from_file
      valid_file = @path.exist? && !@path.size.zero?
      return {} unless valid_file
      list = Array.new
      SharedHelpers.filesystem_access(@path, :read) do |file|
        require "psych"
        Psych.load_stream(file.read) {|doc| list << doc }
      end
      list << @system_metrics
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
  end
end
