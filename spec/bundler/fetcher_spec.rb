require "spec_helper"
require "bundler/fetcher"

describe Bundler::Fetcher do
  subject(:fetcher) { Bundler::Fetcher.new(double("remote", :uri => URI("https://example.com"))) }

  before do
    allow(Bundler).to receive(:root) { Pathname.new("root") }
  end

  describe "#user_agent" do
    it "builds user_agent with current ruby version and Bundler settings" do
      allow(Bundler.settings).to receive(:all).and_return(%w(foo bar))
      expect(fetcher.user_agent).to match(/bundler\/(\d.)/)
      expect(fetcher.user_agent).to match(/rubygems\/(\d.)/)
      expect(fetcher.user_agent).to match(/ruby\/(\d.)/)
      expect(fetcher.user_agent).to match(/options\/foo,bar/)
    end

    describe "include CI information" do
      it "from one CI" do
        with_env_vars({ "JENKINS_URL" => "foo" }) do
          ci_part = fetcher.user_agent.split(" ").find {|x| x.match(/\Aci\//) }
          expect(ci_part).to match("jenkins")
        end
      end

      it "from many CI" do
        with_env_vars({ "TRAVIS" => "foo", "CI_NAME" => "my_ci" }) do
          ci_part = fetcher.user_agent.split(" ").find {|x| x.match(/\Aci\//) }
          expect(ci_part).to match("travis")
          expect(ci_part).to match("my_ci")
        end
      end
    end
  end
end
