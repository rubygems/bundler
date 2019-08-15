# frozen_string_literal: true

module Bundler
  module Metrics
    @path = Bundler.user_bundle_path("metrics")

    def self.opt_out
      @opt_out
    end

    def self.opt_out=(val)
      @opt_out = val
    end

    def self.record_single_metric(key, value)
      return if @opt_out

      @command_metrics ||= Hash.new
      @command_metrics[key] = value
    end

    def self.record_failed_install(gem_name, gem_version)
      return if @opt_out

      init_command_metrics("failed install")
      @command_metrics["gem_name"] = gem_name
      @command_metrics["gem_version"] = gem_version
      write_to_file
    end

    # called when a light command is executed
    def self.record(command_time_taken)
      return if @opt_out

      init_command_metrics(ARGV.first)
      @command_metrics["command_time_taken"] = command_time_taken
      write_to_file
    end

    def self.record_and_send_full_info(time_taken)
      return if @opt_out

      record_system_info
      record_gem_info
      record(time_taken.round(3))
      send_metrics
    end

  private

    def self.init_command_metrics(command)
      @command_metrics ||= Hash.new
      @command_metrics["command"] = command
      options = Bundler.settings.all.join(",")
      @command_metrics["options"] = options unless options.empty?
      require "time"
      @command_metrics["timestamp"] = Time.now.utc.iso8601
    end

    def self.record_gem_info
      @system_metrics["gemfile_gem_count"] = Bundler.definition.dependencies.count
      @system_metrics["installed_gem_count"] = Bundler.definition.specs.count
      @system_metrics["git_gem_count"] = Bundler.definition.sources.git_sources.count
      @system_metrics["path_gem_count"] = Bundler.definition.sources.path_sources.count
      @system_metrics["gem_source_count"] = Bundler.definition.sources.rubygems_sources.count
      require "digest"
      @system_metrics["gem_sources"] = Bundler.definition.sources.rubygems_sources.map(&:to_s).map {|source| Digest::MD5.hexdigest(source[source.index(/http/)..source.rindex("/")]) if source.match(/http/) }
    end

    def self.send_metrics
      # TODO: change URI
      begin
        uri = URI("http://localhost:3000/api/metrics")
        Net::HTTP.start(uri.host, uri.port) do |http| # TODO: add ', :use_ssl => true' later
          req = Net::HTTP::Post.new(uri)
          req["Content-Type"] = "application/json"
          require "json"
          req.body = read_from_file.to_json
          http.request(req)
        end
      rescue SocketError, Errno::ECONNREFUSED
        puts "TCP connection failed"
      rescue OpenSSL::SSL::SSLError
        puts "Certification has probably expired"
      end
      # The file is emptied after sending metrics
      # File::TRUNC is preferable since File.truncate doesn't work for all systems
      open(@path, File::TRUNC) if File.exist?(@path)
    end

    def self.git_info
      begin
        origin = `git remote get-url origin`
        origin = `git config --get remote.origin.url` if origin.empty? # for older git versions
        require "digest"
        @system_metrics["origin"] = Digest::MD5.hexdigest(origin.chomp) unless origin.empty?
      rescue Errno::ENOENT
      end
      begin
        git_ver = `git --version`
        @system_metrics["git_version"] = git_ver[git_ver.index(/\d/)..git_ver.rindex(/\d/)].chomp unless git_ver.empty?
      rescue Errno::ENOENT
      end
    end

    def self.ruby_env_managers
      begin
        rvm_ver = `rvm --version`
        @system_metrics["rvm_version"] = rvm_ver[rvm_ver.index(/\d/)..rvm_ver.rindex(/\d/)].chomp unless rvm_ver.empty?
      rescue Errno::ENOENT
      end
      begin
        rbenv_ver = `rbenv --version`
        @system_metrics["rbenv_version"] = rbenv_ver[rbenv_ver.index(/\d/)..rbenv_ver.rindex(/\d/)].chomp unless rbenv_ver.empty?
      rescue Errno::ENOENT
      end
      begin
        chruby_ver = `chruby --version`
        @system_metrics["chruby_version"] = chruby_ver[chruby_ver.index(/\d/)..chruby_ver.rindex(/\d/)].chomp unless chruby_ver.empty?
      rescue Errno::ENOENT
      end
    end

    def self.ruby_and_bundler_version
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
    end

    def self.cis
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

    def self.ci_info
      cis_var = cis
      @system_metrics["ci"] = cis_var.join(",") if cis_var.any?
    end

    # called when bundle install, outdated, package or pristine are run
    def self.record_system_info
      @system_metrics ||= Hash.new
      # add a random ID so we can consolidate runs server-side
      require "securerandom"
      @system_metrics["request_id"] = SecureRandom.hex(8)
      # hash the origin repository to calculate unique bundler users
      git_info
      ruby_env_managers
      ruby_and_bundler_version
      ci_info
    end

    def self.write_to_file
      SharedHelpers.filesystem_access(@path) do |file|
        FileUtils.mkdir_p(file.dirname) unless File.exist?(file)
        require "psych"
        File.open(file, "a") {|f| f.write(Psych.dump(@command_metrics)) }
      end
    end

    def self.read_from_file
      valid_file = @path.exist? && !@path.size.zero?
      return {} unless valid_file
      list = Array.new
      SharedHelpers.filesystem_access(@path, :read) do |file|
        require "psych"
        list = Psych.load_stream(file.read)
      end
      list << @system_metrics
    end
  end
end
