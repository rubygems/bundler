require "spec_helper"
require "bundler/ruby_version"

describe "Bundler::RubyVersion and its subclasses" do
  let(:version)              { "2.0.0" }
  let(:patchlevel)           { "645" }
  let(:engine)               { "jruby" }
  let(:engine_version)       { "2.0.1" }

  describe Bundler::RubyVersion do
    subject { Bundler::RubyVersion.new(version, patchlevel, engine, engine_version) }

    let(:ruby_version)         { subject }
    let(:other_version)        { version }
    let(:other_patchlevel)     { patchlevel }
    let(:other_engine)         { engine }
    let(:other_engine_version) { engine_version }
    let(:other_ruby_version)   { Bundler::RubyVersion.new(other_version, other_patchlevel, other_engine, other_engine_version) }

    describe "#initialize" do
      context "no engine is passed" do
        let(:engine) { nil }

        it "should set ruby as the engine" do
          expect(subject.engine).to eq("ruby")
        end
      end

      context "no engine_version is passed" do
        let(:engine_version) { nil }

        it "should set engine version as the passed version" do
          expect(subject.engine_version).to eq("2.0.0")
        end
      end
    end
    describe "#to_s" do
      it "should return info string with the ruby version, patchlevel, engine, and engine version" do
        expect(subject.to_s).to eq("ruby 2.0.0p645 (jruby 2.0.1)")
      end

      context "no patchlevel" do
        let(:patchlevel) { nil }

        it "should return info string with the version, engine, and engine version" do
          expect(subject.to_s).to eq("ruby 2.0.0 (jruby 2.0.1)")
        end
      end

      context "engine is ruby" do
        let(:engine) { "ruby" }

        it "should return info string with the ruby version and patchlevel" do
          expect(subject.to_s).to eq("ruby 2.0.0p645")
        end
      end
    end

    describe "#==" do
      shared_examples_for "two ruby versions are not equal" do
        it "should return false" do
          expect(subject).to_not eq(other_ruby_version)
        end
      end

      context "the versions, pathlevels, engines, and engine_versions match" do
        it "should return true" do
          expect(subject).to eq(other_ruby_version)
        end
      end

      context "the versions do not match" do
        let(:other_version) { "1.21.6" }

        it_behaves_like "two ruby versions are not equal"
      end

      context "the patchlevels do not match" do
        let(:other_patchlevel) { "21" }

        it_behaves_like "two ruby versions are not equal"
      end

      context "the engines do not match" do
        let(:other_engine) { "ruby" }

        it_behaves_like "two ruby versions are not equal"
      end

      context "the engine versions do not match" do
        let(:other_engine_version) { "1.11.2" }

        it_behaves_like "two ruby versions are not equal"
      end
    end

    describe "#host" do
      before do
        allow(RbConfig::CONFIG).to receive(:[]).with("host_cpu").and_return("x86_64")
        allow(RbConfig::CONFIG).to receive(:[]).with("host_vendor").and_return("apple")
        allow(RbConfig::CONFIG).to receive(:[]).with("host_os").and_return("darwin14.5.0")
      end

      it "should return an info string with the host cpu, vendor, and os" do
        expect(subject.host).to eq("x86_64-apple-darwin14.5.0")
      end

      it "memoizes the info string with the host cpu, vendor, and os" do
        expect(RbConfig::CONFIG).to receive(:[]).with("host_cpu").once.and_call_original
        expect(RbConfig::CONFIG).to receive(:[]).with("host_vendor").once.and_call_original
        expect(RbConfig::CONFIG).to receive(:[]).with("host_os").once.and_call_original
        2.times { ruby_version.host }
      end
    end

    describe "#gem_version" do
      let(:gem_version_obj) { Gem::Version.new(version) }

      it "should return a Gem::Version instance with the correct version" do
        expect(ruby_version.gem_version).to eq(gem_version_obj)
        expect(ruby_version.gem_version.version).to eq("2.0.0")
      end
    end

    describe "#diff" do
      let(:engine) { "ruby" }

      shared_examples_for "there is a difference in the engines" do
        it "should return a tuple with :engine and the two different engines" do
          expect(ruby_version.diff(other_ruby_version)).to eq([:engine, engine, other_engine])
        end
      end

      shared_examples_for "there is a difference in the versions" do
        it "should return a tuple with :version and the two different versions" do
          expect(ruby_version.diff(other_ruby_version)).to eq([:version, version, other_version])
        end
      end

      shared_examples_for "there is a difference in the engine versions" do
        it "should return a tuple with :engine_version and the two different engine versions" do
          expect(ruby_version.diff(other_ruby_version)).to eq([:engine_version, engine_version, other_engine_version])
        end
      end

      shared_examples_for "there is a difference in the patchlevels" do
        it "should return a tuple with :patchlevel and the two different patchlevels" do
          expect(ruby_version.diff(other_ruby_version)).to eq([:patchlevel, patchlevel, other_patchlevel])
        end
      end

      shared_examples_for "there are no differences" do
        it "should return nil" do
          expect(ruby_version.diff(other_ruby_version)).to be_nil
        end
      end

      context "all things match exactly" do
        it_behaves_like "there are no differences"
      end

      context "detects engine discrepancies first" do
        let(:other_version)        { "2.0.1" }
        let(:other_patchlevel)     { "643" }
        let(:other_engine)         { "rbx" }
        let(:other_engine_version) { "2.0.0" }

        it_behaves_like "there is a difference in the engines"
      end

      context "detects version discrepancies second" do
        let(:other_version)        { "2.0.1" }
        let(:other_patchlevel)     { "643" }
        let(:other_engine_version) { "2.0.0" }

        it_behaves_like "there is a difference in the versions"
      end

      context "detects engine version discrepancies third" do
        let(:other_patchlevel)     { "643" }
        let(:other_engine_version) { "2.0.0" }

        it_behaves_like "there is a difference in the engine versions"
      end

      context "detects patchlevel discrepancies last" do
        let(:other_patchlevel) { "643" }

        it_behaves_like "there is a difference in the patchlevels"
      end

      context "successfully matches gem requirements" do
        let(:version)              { ">= 2.0.0" }
        let(:patchlevel)           { "< 643" }
        let(:engine)               { "ruby" }
        let(:engine_version)       { "~> 2.0.1" }
        let(:other_version)        { "2.0.0" }
        let(:other_patchlevel)     { "642" }
        let(:other_engine)         { "ruby" }
        let(:other_engine_version) { "2.0.5" }

        it_behaves_like "there are no differences"
      end

      context "successfully detects bad gem requirements with versions" do
        let(:version)              { "~> 2.0.0" }
        let(:patchlevel)           { "< 643" }
        let(:engine)               { "ruby" }
        let(:engine_version)       { "~> 2.0.1" }
        let(:other_version)        { "2.1.0" }
        let(:other_patchlevel)     { "642" }
        let(:other_engine)         { "ruby" }
        let(:other_engine_version) { "2.0.5" }

        it_behaves_like "there is a difference in the versions"
      end

      context "successfully detects bad gem requirements with patchlevels" do
        let(:version)              { ">= 2.0.0" }
        let(:patchlevel)           { "< 643" }
        let(:engine)               { "ruby" }
        let(:engine_version)       { "~> 2.0.1" }
        let(:other_version)        { "2.0.0" }
        let(:other_patchlevel)     { "645" }
        let(:other_engine)         { "ruby" }
        let(:other_engine_version) { "2.0.5" }

        it_behaves_like "there is a difference in the patchlevels"
      end

      context "successfully detects bad gem requirements with engine versions" do
        let(:version)              { ">= 2.0.0" }
        let(:patchlevel)           { "< 643" }
        let(:engine)               { "ruby" }
        let(:engine_version)       { "~> 2.0.1" }
        let(:other_version)        { "2.0.0" }
        let(:other_patchlevel)     { "642" }
        let(:other_engine)         { "ruby" }
        let(:other_engine_version) { "2.1.0" }

        it_behaves_like "there is a difference in the engine versions"
      end
    end
  end
end
