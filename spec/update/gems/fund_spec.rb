# frozen_string_literal: true

RSpec.describe "bundle update" do
  let(:config) {}

  before do
    gemfile <<-G
      source "#{file_uri_for(gem_repo1)}"
      gem 'has_metadata'
      gem 'has_funding', '< 2.0'
    G

    bundle! "config set #{config}" if config

    bundle! :install
  end

  shared_examples "a fund message outputter" do
    it "should display fund message for updated gems" do
      expect(out).to include("2 gems you depend on are looking for funding!")
    end
  end

  context "when listed gem is updated" do
    before do
      gemfile <<-G
        source "#{file_uri_for(gem_repo1)}"
        gem 'has_metadata'
        gem 'has_funding'
      G

      bundle! :update, :all => true
    end

    it_behaves_like "a fund message outputter"
  end
end
