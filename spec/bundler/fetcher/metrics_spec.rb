# frozen_string_literal: true

RSpec.describe Bundler::Fetcher::Metrics do
  subject(:metrics) { Bundler::Fetcher::Metrics.new }

  describe "#add_metrics" do
    before do
      metrics.add_metrics
    end
    it "builds metrics_hash with current ruby version and Bundler settings" do
      expect(metrics.metrics_hash["bundler_version"]).to match(/\d\.\d{1,2}\.{0,1}\d{0,1}\.{0,1}(pre){0,1}\.{0,1}\d{0,1}/)
      expect(metrics.metrics_hash["rubygems_version"]).to match(/\d\.\d{1,2}\.{0,1}\d{0,1}\.{0,1}(preview|pre){0,1}\.{0,1}\d{0,1}/)
      expect(metrics.metrics_hash["ruby_version"]).to match(/\d\.\d{1,2}\.{0,1}\d{0,1}\.{0,1}(preview|pre){0,1}\.{0,1}\d{0,1}/)
      expect(metrics.metrics_hash["options"]).to match(/(spec_run)/)
      expect(metrics.metrics_hash["command"]).to match(/(...)/)
      expect(metrics.metrics_hash["time_stamp"]).to match(/\d{4}-\d{2}-\d{2}\S\d{2}:\d{2}:\d{2}\S/)
      expect(metrics.metrics_hash["request_id"]).to match(/\w/)
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

  describe "#write_to_file" do
    before do
      metrics.add_metrics
    end
    it "Creates a file in the global bundler path and writes into it" do
      expect(metrics.path.exist?).to eq(true)
      expect(metrics.path.size.zero?).to eq(false)
    end
  end

  describe "#read_from_file" do
    it "Returns an empty hash if the metrics.yml file has not been found" do
      expect(metrics.read_from_file.empty?).to eq(true)
    end
    it "Reads the metrics hash from the metrics.yml file and returns it" do
      metrics.add_metrics
      expect(metrics.read_from_file.empty?).to eq(false)
    end
  end
end
