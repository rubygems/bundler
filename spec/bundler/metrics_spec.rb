# frozen_string_literal: true

require "bundler/metrics"
require "net/http"
require "time"
require "securerandom"

RSpec.describe Bundler::Metrics do
  subject(:metrics) { Bundler::Metrics.new }

  describe "#add_metrics" do
    it "builds metrics_hash with current ruby version and Bundler settings" do
      expect(metrics.metrics_hash["bundler_version"]).to match(/\d\.\d{1,2}\.{0,1}\d{0,1}\.{0,1}(pre){0,1}\.{0,1}\d{0,1}/)
      expect(metrics.metrics_hash["rubygems_version"]).to match(/\d\.\d{1,2}\.{0,1}\d{0,1}\.{0,1}(preview|pre){0,1}\.{0,1}\d{0,1}/)
      expect(metrics.metrics_hash["ruby_version"]).to match(/\d\.\d{1,2}\.{0,1}\d{0,1}\.{0,1}(preview|pre){0,1}\.{0,1}\d{0,1}/)
      expect(metrics.metrics_hash["options"]).to match(/(spec_run)/)
      expect(metrics.metrics_hash["command"]).to match(/(...)/)
      expect(metrics.metrics_hash["time_stamp"]).to match(/\d{4}-\d{2}-\d{2}\S\d{2}:\d{2}:\d{2}\S/)
      expect(metrics.metrics_hash["request_id"]).to match(/\w/)
    end

    describe "write_to_file" do
      it "Creates a file in the global bundler path and writes into it" do
        expect(metrics.path.exist?).to eq(true)
        expect(metrics.path.size.zero?).to eq(false)
      end
    end

    describe "include CI information" do
      it "from one CI" do
        with_env_vars("JENKINS_URL" => "foo") do
          metrics.add_metrics
          ci_part = metrics.metrics_hash["ci"]
          expect(ci_part).to match("jenkins")
        end
      end

      it "from many CI" do
        with_env_vars("TRAVIS" => "foo", "CI_NAME" => "my_ci") do
          metrics.add_metrics
          ci_part = metrics.metrics_hash["ci"]
          expect(ci_part).to match("travis")
          expect(ci_part).to match("my_ci")
        end
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
      metrics.send_metrics
      expect(metrics.path.empty?).to eq(true)
    end
  end
end
