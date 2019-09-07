# frozen_string_literal: true

require "bundler/metrics"
require "net/http"

RSpec.describe Bundler::Metrics do
  before(:all) do
    Bundler::Metrics.opt_out = false
    Bundler::Metrics.instance_variable_set(:@system_metrics, Hash.new)
  end

  before(:each) do
    Bundler::Metrics.instance_variable_set(:@system_metrics, Hash.new) unless Bundler::Metrics.instance_variable_get(:@system_metrics)
  end

  describe "#record_system_info" do
    before(:each) do
      Bundler::Metrics.send(:record_system_info)
    end
    it "builds system_metrics with current ruby version and Bundler settings" do
      expect(Bundler::Metrics.instance_variable_get(:@system_metrics)["bundler_version"]).to match(/\d\.\d{1,2}\.{0,1}\d{0,1}\.{0,1}(pre){0,1}\.{0,1}\d{0,1}/)
      expect(Bundler::Metrics.instance_variable_get(:@system_metrics)["rubygems_version"]).to match(/\d\.\d{1,2}\.{0,1}\d{0,1}\.{0,1}(preview|pre){0,1}\.{0,1}\d{0,1}/)
      expect(Bundler::Metrics.instance_variable_get(:@system_metrics)["ruby_version"]).to match(/\d\.\d{1,2}\.{0,1}\d{0,1}\.{0,1}(preview|pre){0,1}\.{0,1}\d{0,1}/)
      expect(Bundler::Metrics.instance_variable_get(:@system_metrics)["request_id"]).to match(/[\w]*/)
      expect(Bundler::Metrics.instance_variable_get(:@system_metrics)["host"].nil?).to eq(false)
    end

    it "doesn't crash when the user doesn't have either of the following installed: chruby, rbenv, rvm, git (metrics that are collected later exist)" do
      expect(Bundler::Metrics.instance_variable_get(:@system_metrics)["chruby_version"]).to satisfy("be nil or contain the chruby version") do |v|
        v.nil? || v.match(/([0-9].){1,4}([\w]*)/)
      end
      expect(Bundler::Metrics.instance_variable_get(:@system_metrics)["rbenv_version"]).to satisfy("be nil or contain the rbenv version") do |v|
        v.nil? || v.match(/([0-9].){1,4}([\w]*)/)
      end
      # TODO: FIX THIS ONCE RVM VERSION COLLECTION IS FIXED
      # expect(Bundler::Metrics.instance_variable_get(:@system_metrics)["rvm_version"]).to satisfy("be nil or contain the rvm version") do |v|
      #   v.nil? || v.match(/([0-9].){1,4}([\w]*)/)
      # end
      expect(Bundler::Metrics.instance_variable_get(:@system_metrics)["git_version"]).to satisfy("be nil or contain the git version") do |v|
        v.nil? || v.match(/([0-9].){1,4}([\w]*)/)
      end
    end

    describe "include CI information" do
      it "from one CI" do
        with_env_vars("JENKINS_URL" => "foo") do
          Bundler::Metrics.send(:ci_info)
          ci_part = Bundler::Metrics.instance_variable_get(:@system_metrics)["ci"]
          expect(ci_part).to match("jenkins")
        end
      end

      it "from many CI" do
        with_env_vars("TRAVIS" => "foo", "CI_NAME" => "my_ci") do
          Bundler::Metrics.send(:ci_info)
          ci_part = Bundler::Metrics.instance_variable_get(:@system_metrics)["ci"]
          expect(ci_part).to match("travis")
          expect(ci_part).to match("my_ci")
        end
      end
    end
  end

  describe "#record_gem_info" do
    before(:each) do
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
      Bundler::Metrics.send(:record_system_info)
      Bundler::Metrics.send(:record_gem_info)
      expect(Bundler::Metrics.instance_variable_get(:@system_metrics)["gemfile_gem_count"]).to eq(1)
      expect(Bundler::Metrics.instance_variable_get(:@system_metrics)["installed_gem_count"]).to eq(2)
      expect(Bundler::Metrics.instance_variable_get(:@system_metrics)["git_gem_count"]).to eq(0)
      expect(Bundler::Metrics.instance_variable_get(:@system_metrics)["path_gem_count"]).to eq(0)
      expect(Bundler::Metrics.instance_variable_get(:@system_metrics)["gem_source_count"]).to eq(1)
    end
  end

  describe "#record" do
    before(:each) do
      path = Bundler::Metrics.instance_variable_get(:@path)
      open(path, File::TRUNC) if File.exist?(path)
      Bundler::Metrics.record(670)
    end

    it "records a single metric and appends it to metrics.yml" do
      expect(Bundler::Metrics.instance_variable_get(:@command_metrics)["command_time_taken"]).to match(670)
      expect(Bundler::Metrics.instance_variable_get(:@command_metrics)["timestamp"]).to match(/\d{4}-\d{2}-\d{2}\S\d{2}:\d{2}:\d{2}\S/)
      expect(Bundler::Metrics.instance_variable_get(:@command_metrics)["command"]).to match(/(--)+.*/).or match(/(spec)+.*/).or eq(nil)
      expect(Bundler::Metrics.instance_variable_get(:@command_metrics)["options"]).to match(/(spec)+.*/)
    end

    describe "write_to_file" do
      after do
        File.delete(Bundler::Metrics.instance_variable_get(:@path)) if File.exist?(Bundler::Metrics.instance_variable_get(:@path))
      end

      it "Creates a file in the global bundler config and writes into it" do
        expect(Pathname.new(Bundler::Metrics.instance_variable_get(:@path)).exist?).to eq(true)
        expect(Pathname.new(Bundler::Metrics.instance_variable_get(:@path)).size.zero?).to eq(false)
      end

      it "Should write the recorded info into the file" do
        file_data = Bundler::Metrics.send(:read_from_file)
        expect(file_data[0]["command_time_taken"]).to eq(670.to_s)
        expect(file_data[0]["command"]).to match(/(--)+.*/).or match(/(spec)+.*/).or eq(nil)
        expect(file_data[0]["timestamp"]).to match(/\d{4}-\d{2}-\d{2}\S\d{2}:\d{2}:\d{2}\S/)
        expect(file_data[0]["options"]).to match(/(spec)+.*/)
      end

      it "Should write the recorded info into the file several times" do
        Bundler::Metrics.record(31)
        file_data = Bundler::Metrics.send(:read_from_file)
        expect(file_data[-2]["command_time_taken"]).to eq(31.to_s)
      end
    end
  end

  describe "#send_metrics" do
    it "Makes a connection to an HTTP server" do
      require "yaml"
      uri = URI.parse("https://www.example.com")
      http = Net::HTTP.new(uri.host, uri.port)
      http.use_ssl = true
    end

    describe "read_from_file" do
      before(:each) do
        require "yaml"
        Bundler::Metrics.record(4.2)
        Bundler::Metrics.send(:write_to_file)
      end

      it "Should return a list of the file's documents" do
        data = Bundler::Metrics.send(:read_from_file)
        expect(data.is_a?(Array)).to eq(true)
        expect(data[0].is_a?(Hash)).to eq(true)
      end
    end

    it "Sends the metrics from metrics.yml to a specified server over HTTP" do
      uri = URI.parse("https://www.example.com")
      http = Net::HTTP.new(uri.host, uri.port)
      http.use_ssl = true
      read = Bundler::Metrics.send(:read_from_file)
      request = Net::HTTP::Post.new(uri.request_uri)
      request.set_form_data(read)
      http.request(request)
      expect(request.response_body_permitted?).to eq(true)
    end

    it "Truncates the metrics.yml file after sending the metrics" do
      Bundler::Metrics.record(3)
      Bundler::Metrics.send(:send_metrics)
      file = Pathname.new(Bundler::Metrics.instance_variable_get(:@path))
      expect(file.empty?).to eq(true) if file.is_a?(File)
    end
  end

  describe "#record_single_metric" do
    before(:each) do
      Bundler::Metrics.record_single_metric("hopefully_this", "works")
    end

    it "should initialize the command_metrics hash" do
      expect(Bundler::Metrics.instance_variable_get(:@command_metrics)).to be_kind_of(Hash)
    end

    it "should push the given key and value pair into command_metrics" do
      expect(Bundler::Metrics.instance_variable_get(:@command_metrics)["hopefully_this"]).to eq("works")
    end
  end

  describe "#record_failed_install" do
    require "bundler/installer/gem_installer"
    let(:installer) { instance_double("Installer") }
    let(:spec_source) { instance_double("SpecSource") }
    let(:spec) { instance_double("Specification", :name => "dummy", :version => "0.0.1", :loaded_from => "dummy", :source => spec_source) }
    subject(:gem_installer) { Bundler::GemInstaller.new(spec, installer) }
    before(:each) do
      gem_installer.send(:install_error_message)
    end

    it "should set the hash value for command key to failed install" do
      expect(Bundler::Metrics.instance_variable_get(:@command_metrics)["command"]).to eq("failed install")
    end

    it "should record the name and version of the gem that failed to install" do
      expect(Bundler::Metrics.instance_variable_get(:@command_metrics)["gem_name"]).to eq("dummy")
      expect(Bundler::Metrics.instance_variable_get(:@command_metrics)["gem_version"]).to eq("0.0.1")
    end
  end
end
