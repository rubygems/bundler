# frozen_string_literal: true
require "spec_helper"

describe Bundler::GemVersionPromoter do
  context "conservative resolver" do
    def versions(result)
      result.flatten.map(&:version).map(&:to_s)
    end

    def make_instance(*args)
      @gvp = Bundler::GemVersionPromoter.new(*args).tap do |gvp|
        gvp.class.class_eval { public :filter_dep_specs, :sort_dep_specs }
      end
    end

    def unlocking(options = {})
      make_instance(Bundler::SpecSet.new([]), ["foo"]).tap do |p|
        p.level = options[:level] if options[:level]
        p.strict = options[:strict] if options[:strict]
      end
    end

    def keep_locked(options = {})
      make_instance(Bundler::SpecSet.new([]), ["bar"]).tap do |p|
        p.level = options[:level] if options[:level]
        p.strict = options[:strict] if options[:strict]
      end
    end

    def build_spec_group(name, version)
      build_spec(name, version).map {|s| Array(s) }
    end

    # Rightmost (highest array index) in result is most preferred.
    # Leftmost (lowest array index) in result is least preferred.
    # `build_spec_group` has all version of gem in index.
    # `build_spec` is the version currently in the .lock file.
    #
    # In default (not strict) mode, all versions in the index will
    # be returned, allowing Bundler the best chance to resolve all
    # dependencies, but sometimes resulting in upgrades that some
    # would not consider conservative.
    context "filter specs (strict) (minor not allowed)" do
      it "when keeping build_spec, keep current, next release" do
        keep_locked(:level => :patch)
        res = @gvp.filter_dep_specs(
          build_spec_group("foo", %w(1.7.8 1.7.9 1.8.0)),
          build_spec("foo", "1.7.8").first)
        expect(versions(res)).to eq %w(1.7.9 1.7.8)
      end

      it "when unlocking prefer next release first" do
        unlocking
        res = @gvp.filter_dep_specs(
          build_spec_group("foo", %w(1.7.8 1.7.9 1.8.0)),
          build_spec("foo", "1.7.8").first)
        expect(versions(res)).to eq %w(1.7.8 1.7.9)
      end

      it "when unlocking keep current when already at latest release" do
        unlocking
        res = @gvp.filter_dep_specs(
          build_spec_group("foo", %w(1.7.9 1.8.0 2.0.0)),
          build_spec("foo", "1.7.9").first)
        expect(versions(res)).to eq %w(1.7.9)
      end
    end

    context "filter specs (strict) (minor preferred)" do
      it "should have specs" # MODO: so, y'know, like, maybe ... make some?
    end

    context "sort specs (not strict) (minor not allowed)" do
      it "when not unlocking, same order but make sure build_spec version is most preferred to stay put" do
        keep_locked
        res = @gvp.sort_dep_specs(
          build_spec_group("foo", %w(1.7.6 1.7.7 1.7.8 1.7.9 1.8.0 1.8.1 2.0.0 2.0.1)),
          build_spec("foo", "1.7.7").first)
        expect(versions(res)).to eq %w(2.0.0 2.0.1 1.8.0 1.8.1 1.7.8 1.7.9 1.7.7)
      end

      it "when unlocking favor next release, then current over minor increase" do
        unlocking
        res = @gvp.sort_dep_specs(
          build_spec_group("foo", %w(1.7.7 1.7.8 1.7.9 1.8.0)),
          build_spec("foo", "1.7.8").first)
        expect(versions(res)).to eq %w(1.8.0 1.7.8 1.7.9)
      end

      it "when unlocking do proper integer comparison, not string" do
        unlocking
        res = @gvp.sort_dep_specs(
          build_spec_group("foo", %w(1.7.7 1.7.8 1.7.9 1.7.15 1.8.0)),
          build_spec("foo", "1.7.8").first)
        expect(versions(res)).to eq %w(1.8.0 1.7.8 1.7.9 1.7.15)
      end

      it "leave current when unlocking but already at latest release" do
        unlocking
        res = @gvp.sort_dep_specs(
          build_spec_group("foo", %w(1.7.9 1.8.0 2.0.0)),
          build_spec("foo", "1.7.9").first)
        expect(versions(res)).to eq %w(2.0.0 1.8.0 1.7.9)
      end
    end

    context "sort specs (not strict) (minor allowed)" do
      it "when unlocking favor next release, then minor increase over current" do
        unlocking(:level => :minor)
        res = @gvp.sort_dep_specs(
          build_spec_group("foo", %w(0.2.0 0.3.0 0.3.1 0.9.0 1.0.0 2.0.0 2.0.1)),
          build_spec("foo", "0.2.0").first)
        expect(versions(res)).to eq %w(2.0.0 2.0.1 1.0.0 0.2.0 0.3.0 0.3.1 0.9.0)
      end
    end

    context "caching search results" do
      it "should dup the output to protect the cache" do
        # Bundler will (somewhere) do this on occasion during a large resolution.
        # Let's protect against it.
        gvp = Bundler::GemVersionPromoter.new

        dep = Bundler::DepProxy.new(Gem::Dependency.new("foo", ">= 0"), "ruby")
        sg = build_spec_group("foo", %w(2.4.0))
        res = gvp.sort_versions(dep, sg)
        res.clear
        expect(gvp.sort_versions(dep, sg)).to_not eq []
      end
    end
  end
end
