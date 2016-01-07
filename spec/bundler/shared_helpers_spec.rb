require "spec_helper"
require "bundler/shared_helpers"

describe Bundler::SharedHelpers do
  describe "#default_gemfile" do
    subject { Bundler::SharedHelpers.default_gemfile }
    before do
      ENV["BUNDLE_GEMFILE"] = "/path/Gemfile"
    end
    context "Gemfile is present" do
      it "returns the Gemfile path" do
        expected_gemfile_path = Pathname.new("/path/Gemfile")
        expect(subject).to eq(expected_gemfile_path)
      end
    end
    context "Gemfile is not present" do
      before do
        ENV["BUNDLE_GEMFILE"] = nil
      end
      it "raises a GemfileNotFound error" do
        expect { subject }.to raise_error(Bundler::GemfileNotFound, "Could not locate Gemfile")
      end
    end
  end
  describe "#default_lockfile" do
    subject { Bundler::SharedHelpers.default_lockfile }
    context "gemfile is gems.rb" do
      before do
        gemfile_path = Pathname.new("/path/gems.rb")
        allow(Bundler::SharedHelpers).to receive(:default_gemfile).and_return(gemfile_path)
      end
      it "returns the gems.locked path" do
        expected_lockfile_path = Pathname.new("/path/gems.locked")
        expect(subject).to eq(expected_lockfile_path)
      end
    end
    context "is a regular Gemfile" do
      before do
        gemfile_path = Pathname.new("/path/Gemfile")
        allow(Bundler::SharedHelpers).to receive(:default_gemfile).and_return(gemfile_path)
      end
      it "returns the lock file path" do
        expected_lockfile_path = Pathname.new("/path/Gemfile.lock")
        expect(subject).to eq(expected_lockfile_path)
      end
    end
  end
  describe "#default_bundle_dir" do
    subject { Bundler::SharedHelpers.default_bundle_dir }
    context ".bundle does not exist" do
      it "returns nil" do
        expect(subject).to eq(nil)
      end
    end
    context ".bundle is global .bundle" do
      before do
        Dir.mkdir ".bundle"
        global_rubygems_dir = Pathname.new("#{bundled_app}")
        allow(Bundler.rubygems).to receive(:user_home).and_return(global_rubygems_dir)
      end
      it "returns nil" do
        expect(subject).to eq(nil)
      end
    end
    context ".bundle is not global .bundle" do
      before do
        Dir.mkdir ".bundle"
        global_rubygems_dir = Pathname.new("/path/rubygems")
        allow(Bundler.rubygems).to receive(:user_home).and_return(global_rubygems_dir)
      end
      it "returns the .bundle path" do
        expected_bundle_dir_path = Pathname.new("#{bundled_app}/.bundle")
        expect(subject).to eq(expected_bundle_dir_path)
      end
    end
  end
  describe "#const_get_safely" do
    module TargetNamespace
      VALID_CONSTANT = 1
    end
    context "when the namespace does have the requested constant" do
      subject { Bundler::SharedHelpers.const_get_safely(:VALID_CONSTANT, TargetNamespace) }
      it "returns the value of the requested constant" do
        expect(subject).to eq(1)
      end
    end
    context "when the requested constant is passed as a string" do
      subject { Bundler::SharedHelpers.const_get_safely("VALID_CONSTANT", TargetNamespace) }
      it "returns the value of the requested constant" do
        expect(subject).to eq(1)
      end
    end
    context "when the namespace does not have the requested constant" do
      subject { Bundler::SharedHelpers.const_get_safely("INVALID_CONSTANT", TargetNamespace) }
      it "returns nil" do
        expect(subject).to eq(nil)
      end
    end
  end
end
