require "spec_helper"

describe "bundle install with gems on multiple sources" do
  # repo1 is built automatically before all of the specs run
  # it contains rack-obama 1.0.0 and rack 0.9.1 & 1.0.0 amongst other gems

  context "without source affinity" do
    before do
      # Oh no! Someone evil is trying to hijack rack :(
      # need this to be broken to check for correct source ordering
      build_repo gem_repo3 do
        build_gem "rack", repo3_rack_version do |s|
          s.write "lib/rack.rb", "RACK = 'FAIL'"
        end
      end
    end

    context "when the same version of the same gem is in multiple sources" do
      let(:repo3_rack_version) { "1.0.0" }

      before do
        gemfile <<-G
          source "file://#{gem_repo3}"
          source "file://#{gem_repo1}"
          gem "rack-obama"
          gem "rack"
        G
      end

      it "warns about ambiguous gems, but installs anyway, prioritizing sources last to first" do
        bundle :install

        expect(out).to include("Warning: the gem 'rack' was found in multiple sources.")
        expect(out).to include("Installed from: file:#{gem_repo1}")
        should_be_installed("rack-obama 1.0.0", "rack 1.0.0")
      end
    end

    context "when different versions of the same gem are in multiple sources" do
      let(:repo3_rack_version) { "1.2" }

      before do
        gemfile <<-G
          source "file://#{gem_repo3}"
          source "file://#{gem_repo1}"
          gem "rack-obama"
          gem "rack", "1.0.0" # force it to install the working version in repo1
        G
      end

      it "warns about ambiguous gems, but installs anyway" do
        bundle :install

        expect(out).to include("Warning: the gem 'rack' was found in multiple sources.")
        expect(out).to include("Installed from: file:#{gem_repo1}")
        should_be_installed("rack-obama 1.0.0", "rack 1.0.0")
      end
    end
  end
end
