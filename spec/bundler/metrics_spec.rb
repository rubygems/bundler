# frozen_string_literal: true

require "bundler/metrics"
require "net/http"
require "time"
require "securerandom"

RSpec.describe Bundler::Metrics do
  subject(:metrics) { Bundler::Metrics.new }

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

  describe "#record" do
    before do
      metrics.record("time_taken", 3)
    end
    it "records a single metric and appends it to metrics.yml" do
      expect(metrics.instance_variable_get(:@standalone_metrics)["time_taken"]).to match(3)
      expect(metrics.instance_variable_get(:@standalone_metrics)["timestamp"]).to match(/\d{4}-\d{2}-\d{2}\S\d{2}:\d{2}:\d{2}\S/)
      expect(metrics.instance_variable_get(:@standalone_metrics)["command"]).to match(%r{(spec\/bundler\/metrics_spec.rb)})
      expect(metrics.instance_variable_get(:@standalone_metrics)["options"]).to match(/(spec_run)/)
    end
    describe "write_to_file" do
      after do
        File.delete(metrics.instance_variable_get(:@path)) if File.exist?(metrics.instance_variable_get(:@path))
      end
      it "Creates a file in the global bundler path and writes into it" do
        expect(Pathname.new(metrics.instance_variable_get(:@path)).exist?).to eq(true)
        expect(Pathname.new(metrics.instance_variable_get(:@path)).size.zero?).to eq(false)
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
        metrics.record("time_taken", 4.2)
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
      metrics.record("time_taken", 3)
      metrics.send_metrics
      expect(Pathname.new(metrics.instance_variable_get(:@path)).empty?).to eq(true)
    end
  end
end
