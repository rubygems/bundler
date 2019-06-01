# frozen_string_literal: true

RSpec.describe Bundler::Fetcher::Metrics do
  subject(:metrics) { Bundler::Fetcher::Metrics.new }

  describe "#add_metrics" do
    before do
      metrics.add_metrics
    end
    it "builds metrics_hash with current ruby version and Bundler settings" do
      expect(metrics.metrics_hash["Bundler Version"]).to match(%r{bundler/(\d.)})
      expect(metrics.metrics_hash["Rubygems Version"]).to match(%r{rubygems/(\d.)})
      expect(metrics.metrics_hash["Ruby Versions"]).to match(%r{ruby/(\d.)})
      expect(metrics.metrics_hash["Options"]).to match(%r{options/spec_run})
      expect(metrics.metrics_hash["Command"]).to match(%r{command/(...)})
    end

    describe "include CI information" do
      it "from one CI" do
        with_env_vars("JENKINS_URL" => "foo") do
          metrics.add_metrics
          ci_part = metrics.metrics_hash["CI"]
          expect(ci_part).to match("jenkins")
        end
      end

      it "from many CI" do
        with_env_vars("TRAVIS" => "foo", "CI_NAME" => "my_ci") do
          metrics.add_metrics
          ci_part = metrics.metrics_hash["CI"]
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
