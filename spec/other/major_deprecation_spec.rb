# frozen_string_literal: true
require "spec_helper"

describe "major deprecations" do
  matcher :have_major_deprecation do |expected|
    diffable
    match do |actual|
      actual.split(/^\[DEPRECATED FOR 2\.0\]\s*/).any? do |d|
        !d.empty? && values_match?(expected, d)
      end
    end
  end

  let(:warnings) { out } # change to err in 2.0

  before do
    bundle "config major_deprecations true"

    install_gemfile <<-G
      source "file:#{gem_repo1}"
      ruby #{RUBY_VERSION.dump}
      gem "rack"
    G
  end

  describe "bundle_ruby" do
    it "prints a deprecation" do
      bundle_ruby :expect_err => true
      out.gsub! "\nruby #{RUBY_VERSION}", ""
      expect(warnings).to have_major_deprecation "the bundle_ruby executable has been removed in favor of `bundle platform --ruby`"
    end
  end

  describe "Bundler" do
    describe ".clean_env" do
      it "is deprecated in favor of .original_env" do
        source = "Bundler.clean_env"
        bundle "exec ruby -e #{source.dump}"
        expect(warnings).to have_major_deprecation "`Bundler.clean_env` has weird edge cases, use `.original_env` instead"
      end
    end

    shared_examples_for "environmental deprecations" do |trigger|
      describe "ruby version", :ruby => "< 2.0" do
        it "requires a newer ruby version" do
          instance_eval(&trigger)
          expect(warnings).to have_major_deprecation "Bundler will only support ruby >= 2.0, you are running #{RUBY_VERSION}"
        end
      end

      describe "rubygems version", :rubygems => "< 2.0" do
        it "requires a newer rubygems version" do
          instance_eval(&trigger)
          expect(warnings).to have_major_deprecation "Bundler will only support rubygems >= 2.4, you are running #{Gem::VERSION}"
        end
      end
    end

    describe "-rbundler/setup" do
      it_behaves_like "environmental deprecations", proc { ruby "require 'bundler/setup'" }
    end

    describe "Bundler.setup" do
      it_behaves_like "environmental deprecations", proc { ruby "require 'bundler'; Bundler.setup" }
    end

    describe "bundle check" do
      it_behaves_like "environmental deprecations", proc { bundle :check }
    end
  end
end
