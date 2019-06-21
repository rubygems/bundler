# frozen_string_literal: true

require "bundler/metrics"
require "net/http"
require "time"
require "securerandom"

RSpec.describe Bundler::Metrics do
  subject(:metrics) { Bundler.init_metrics }

  describe "#record_system_info" do
    before do
      metrics.record_system_info
    end
    it "builds system_metrics with current ruby version and Bundler settings" do
      expect(metrics.instance_variable_get(:@system_metrics)["bundler_version"]).to match(/\d\.\d{1,2}\.{0,1}\d{0,1}\.{0,1}(pre){0,1}\.{0,1}\d{0,1}/)
      expect(metrics.instance_variable_get(:@system_metrics)["rubygems_version"]).to match(/\d\.\d{1,2}\.{0,1}\d{0,1}\.{0,1}(preview|pre){0,1}\.{0,1}\d{0,1}/)
      expect(metrics.instance_variable_get(:@system_metrics)["ruby_version"]).to match(/\d\.\d{1,2}\.{0,1}\d{0,1}\.{0,1}(preview|pre){0,1}\.{0,1}\d{0,1}/)
      expect(metrics.instance_variable_get(:@system_metrics)["request_id"]).to match(/\w/)
      expect(metrics.instance_variable_get(:@system_metrics)["host"].nil?).to eq(false)
    end

    it "doesn't crash when the user doesn't have either of the following installed: chruby, rbenv, rvm, git (metrics that are collected later exist)" do
      expect(metrics.instance_variable_get(:@system_metrics)["chruby_version"]).to satisfy("be nil or contain the chruby version") do |v|
        v.nil? || v.match(/([0-9].)*/)
      end
      expect(metrics.instance_variable_get(:@system_metrics)["rbenv_version"]).to satisfy("be nil or contain the rbenv version") do |v|
        v.nil? || v.match(/([0-9].)*/)
      end
      expect(metrics.instance_variable_get(:@system_metrics)["rvm_version"]).to satisfy("be nil or contain the rvm version") do |v|
        v.nil? || v.match(/([0-9].)*/)
      end
      expect(metrics.instance_variable_get(:@system_metrics)["git_version"]).to satisfy("be nil or contain the git version") do |v|
        v.nil? || v.match(/([0-9].)*/)
      end
    end

    describe "include CI information" do
      it "from one CI" do
        with_env_vars("JENKINS_URL" => "foo") do
          metrics.record_system_info
          ci_part = metrics.instance_variable_get(:@system_metrics)["ci"]
          expect(ci_part).to match("jenkins")
        end
      end

      it "from many CI" do
        with_env_vars("TRAVIS" => "foo", "CI_NAME" => "my_ci") do
          metrics.record_system_info
          ci_part = metrics.instance_variable_get(:@system_metrics)["ci"]
          expect(ci_part).to match("travis")
          expect(ci_part).to match("my_ci")
        end
      end
    end
  end

  describe "#record_gem_info" do
    before do
      Bundler.init_metrics
      build_repo2 do
        build_gem "rails", "3.0" do |s|
          s.add_dependency "bundler", ">= 0.9.0.pre"
        end
        build_gem "bundler", "0.9.1"
        build_gem "bundler", Bundler::VERSION
      end
    end
    it "records installed gem metrics" do
      install_gemfile <<-G
        source "file://#{gem_repo2}"
        gem "rails", "3.0"
      G
      Bundler.metrics.record_system_info
      Bundler.metrics.send(:record_gem_info)
      expect(Bundler.metrics.instance_variable_get(:@system_metrics)["gemfile_gem_count"]).to eq(1)
      expect(Bundler.metrics.instance_variable_get(:@system_metrics)["installed_gem_count"]).to eq(2)
      expect(Bundler.metrics.instance_variable_get(:@system_metrics)["git_gem_count"]).to eq(0)
      expect(Bundler.metrics.instance_variable_get(:@system_metrics)["path_gem_count"]).to eq(0)
      expect(Bundler.metrics.instance_variable_get(:@system_metrics)["gem_source_count"]).to eq(1)
    end
  end

  describe "#record" do
    before do
      metrics.record(670)
    end

    it "records a single metric and appends it to metrics.yml" do
      expect(metrics.instance_variable_get(:@command_metrics)["command_time_taken"]).to match(670)
      expect(metrics.instance_variable_get(:@command_metrics)["timestamp"]).to match(/\d{4}-\d{2}-\d{2}\S\d{2}:\d{2}:\d{2}\S/)
      expect(metrics.instance_variable_get(:@command_metrics)["command"]).to match(%r{(spec\/bundler\/metrics_spec.rb)})
      expect(metrics.instance_variable_get(:@command_metrics)["options"]).to match(/(spec_run)/)
    end

    describe "write_to_file" do
      after do
        File.delete(metrics.instance_variable_get(:@path)) if File.exist?(metrics.instance_variable_get(:@path))
      end

      it "Creates a file in the global bundler path and writes into it" do
        expect(Pathname.new(metrics.instance_variable_get(:@path)).exist?).to eq(true)
        expect(Pathname.new(metrics.instance_variable_get(:@path)).size.zero?).to eq(false)
      end

      it "Should write the recorded info into the file" do
        file_data = metrics.send(:read_from_file)
        expect(file_data[0]["command_time_taken"]).to eq(670)
        expect(file_data[0]["command"]).to match(%r{(spec\/bundler\/metrics_spec.rb)})
        expect(file_data[0]["timestamp"]).to match(/\d{4}-\d{2}-\d{2}\S\d{2}:\d{2}:\d{2}\S/)
        expect(file_data[0]["options"]).to match(/(spec_run)/)
      end

      it "Should write the recorded info into the file several time" do
        metrics.record(31)
        file_data = metrics.send(:read_from_file)
        expect(file_data[1]["command_time_taken"]).to eq(31)
      end
    end
  end

  describe "#send_metrics" do
    it "Makes a connection to an HTTP server" do
      uri = URI.parse("https://www.example.com")
      http = Net::HTTP.new(uri.host, uri.port)
      http.use_ssl = true
    end

    describe "read_from_file" do
      before do
        metrics.record(4.2)
        metrics.send(:write_to_file)
      end

      it "Should return a list of the file's documents" do
        data = metrics.send(:read_from_file)
        expect(data.is_a?(Array)).to eq(true)
        expect(data[0].is_a?(Hash)).to eq(true)
      end
    end

    it "Sends the metrics from metrics.yml to a specified server over HTTP" do
      uri = URI.parse("https://www.example.com")
      http = Net::HTTP.new(uri.host, uri.port)
      http.use_ssl = true
      read = metrics.send(:read_from_file)
      request = Net::HTTP::Post.new(uri.request_uri)
      request.set_form_data(read)
      http.request(request)
      expect(request.response_body_permitted?).to eq(true)
    end

    it "Truncates the metrics.yml file after sending the metrics" do
      metrics.record(3)
      metrics.send_metrics
      expect(Pathname.new(metrics.instance_variable_get(:@path)).empty?).to eq(true)
    end
  end

  describe "#record_single_metric" do
    before do
      metrics.record_single_metric("hopefully_this", "works")
    end

    it "should initialize the command_metrics hash" do
      expect(metrics.instance_variable_get(:@command_metrics)).to be_kind_of(Hash)
    end

    it "should push the given key and value pair into command_metrics" do
      expect(metrics.instance_variable_get(:@command_metrics)["hopefully_this"]).to eq("works")
    end
  end

  describe "#record_failed_install" do
    require "bundler/installer/gem_installer"
    let(:installer) { instance_double("Installer") }
    let(:spec_source) { instance_double("SpecSource") }
    let(:spec) { instance_double("Specification", :name => "dummy", :version => "0.0.1", :loaded_from => "dummy", :source => spec_source) }
    subject(:gem_installer) { Bundler::GemInstaller.new(spec, installer) }
    before do
      Bundler.init_metrics
      gem_installer.send(:install_error_message)
    end

    it "should set the hash value for command key to failed install" do
      expect(Bundler.metrics.instance_variable_get(:@command_metrics)["command"]).to eq("failed install")
    end

    it "should record the name and version of the gem that failed to install" do
      expect(Bundler.metrics.instance_variable_get(:@command_metrics)["gem_name"]).to eq("dummy")
      expect(Bundler.metrics.instance_variable_get(:@command_metrics)["gem_version"]).to eq("0.0.1")
    end
  end
end
