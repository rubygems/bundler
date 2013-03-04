require 'spec_helper'

describe "post bundle message" do
  before :each do
    gemfile <<-G
        source "file://#{gem_repo1}"
        gem "rack"
        gem "activesupport", "2.3.5", :group => [:emo, :test]
        group :test do
          gem "rspec"
        end
    G
  end

  let(:bundle_show_message)       {"Use `bundle show [gemname]` to see where a bundled gem is installed.\n"}
  let(:bundle_deployment_message) {"It was installed into ./vendor/bundle"}
  let(:bundle_complete_message)   {"Your bundle is complete!"}
  let(:bundle_updated_message)    {"Your bundle is updated!"}

  describe "for fresh bundle install" do
    it "without any options" do
      bundle :install
      expect(out).to include(bundle_show_message)
      expect(out).not_to include("Skipped groups")
      expect(out).to include(bundle_complete_message)
    end

    it "with --without one group" do
      bundle :install, :without => :emo
      expect(out).to include(bundle_show_message)
      expect(out).to include("Skipped groups for this bundle are: emo.\n")
      expect(out).to include(bundle_complete_message)
    end

    it "with --without more group" do
      bundle "install --without emo test"
      expect(out).to include(bundle_show_message)
      expect(out).to include("Skipped groups for this bundle are: emo test.\n")
      expect(out).to include(bundle_complete_message)
    end

    describe "with --deployment and" do
      it "without any options" do
        bundle :install
        bundle "install --deployment", :exitstatus => true
        expect(out).to include(bundle_deployment_message)
        expect(out).not_to include("Skipped groups")
        expect(out).to include(bundle_complete_message)
      end

      it "with --without one group" do
        bundle :install
        bundle "install  --without emo --deployment"
        expect(out).to include(bundle_deployment_message)
        expect(out).to include("Skipped groups for this bundle are: emo.\n")
        expect(out).to include(bundle_complete_message)
      end

      it "with --without more group" do
        bundle :install
        bundle "install  --without emo test --deployment"
        expect(out).to include(bundle_deployment_message)
        expect(out).to include("Skipped groups for this bundle are: emo test.\n")
        expect(out).to include(bundle_complete_message)
      end
    end
  end

  describe "for second bundle install run" do
    it "without any options" do
      2.times { bundle :install }
      bundle :install
      expect(out).to include(bundle_show_message)
      expect(out).not_to include("Skipped groups")
      expect(out).to include(bundle_complete_message)
    end

    it "with --without one group" do
      2.times { bundle :install, :without => :emo }
      expect(out).to include(bundle_show_message)
      expect(out).to include("Skipped groups for this bundle are: emo.\n")
      expect(out).to include(bundle_complete_message)
    end

    it "with --without more group" do
      2.times { bundle "install --without emo test" }
      expect(out).to include(bundle_show_message)
      expect(out).to include("Skipped groups for this bundle are: emo test.\n")
      expect(out).to include(bundle_complete_message)
    end
  end

  describe "for bundle update" do
    it "without any options" do
      bundle :install
      bundle :update
      expect(out).to include(bundle_show_message)
      expect(out).not_to include("Skipped groups")
      expect(out).to include(bundle_updated_message)
    end

    it "with --without one group" do
      bundle :install, :without => :emo
      bundle :update
      expect(out).to include(bundle_show_message)
      expect(out).to include("Skipped groups for this bundle are: emo.\n")
      expect(out).to include(bundle_updated_message)
    end

    it "with --without more group" do
      bundle "install --without emo test"
      bundle :update
      expect(out).to include(bundle_show_message)
      expect(out).to include("Skipped groups for this bundle are: emo test.\n")
      expect(out).to include(bundle_updated_message)
    end
  end
end
