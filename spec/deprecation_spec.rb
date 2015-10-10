# frozen_string_literal: true
require "spec_helper"

describe "Bundler version 1.99" do
  context "when bundle is run" do
    it "should not warn about gems.rb" do
      create_file "gems.rb", <<-G
        source "file://#{gem_repo1}"
        gem "rack"
      G

      bundle :install
      expect(err).to lack_errors
    end

    it "should print a Gemfile deprecation warning" do
      install_gemfile <<-G
        source "file://#{gem_repo1}"
        gem "rack"
      G

      expect(err).to include("DEPRECATION: Gemfile and Gemfile.lock are " \
       "deprecated and will be replaced with gems.rb and gems.locked in " \
       "Bundler 2.0.")
    end

    context "with flags" do
      it "should print a deprecation warning about autoremembering flags" do
        install_gemfile <<-G, :path => "vendor/bundle"
          source "file://#{gem_repo1}"
          gem "rack"
        G

        expect(err).to include("DEPRECATION")
        expect(err).to include("flags passed to commands will no longer be automatically remembered.")
      end
    end
  end

  context "when Bundler.setup is run in a ruby script" do
    it "should print a single deprecation warning" do
      install_gemfile <<-G
        source "file://#{gem_repo1}"
        gem "rack", :group => :test
      G

      ruby <<-RUBY
        require 'rubygems'
        require 'bundler'
        require 'bundler/vendored_thor'

        Bundler.ui = Bundler::UI::Shell.new
        Bundler.setup
        Bundler.setup
      RUBY

      expect(err).to eq("DEPRECATION: Gemfile and Gemfile.lock are " \
       "deprecated and will be replaced with gems.rb and gems.locked in " \
       "Bundler 2.0.")
    end
  end

  context "when `bundler/deployment` is required in a ruby script" do
    it "should print a capistrano deprecation warning" do
      install_gemfile <<-G
        source "file://#{gem_repo1}"
        gem "rack", :group => :test
      G

      ruby(<<-RUBY, :expect_err => true)
        require 'bundler/deployment'
      RUBY

      expect(err).to eq("DEPRECATION: Bundler no longer integrates " \
                             "with Capistrano, but Capistrano provides " \
                             "its own integration with Bundler via the " \
                             "capistrano-bundler gem. Use it instead.")
    end
  end

  describe Bundler::Dsl do
    before do
      @rubygems = double("rubygems")
      allow(Bundler::Source::Rubygems).to receive(:new) { @rubygems }
    end

    context "with github gems" do
      it "warns about the https change" do
        allow(Bundler.ui).to receive(:deprecate)
        msg = "The :github option uses the git: protocol, which is not secure. " \
        "Bundler 2.0 will use the https: protocol, which is secure. Enable this change now by " \
        "running `bundle config github.https true`."
        expect(Bundler.ui).to receive(:deprecate).with(msg)
        subject.gem("sparks", :github => "indirect/sparks")
      end

      it "upgrades to https on request" do
        Bundler.settings["github.https"] = true
        subject.gem("sparks", :github => "indirect/sparks")
        github_uri = "https://github.com/indirect/sparks.git"
        expect(subject.dependencies.first.source.uri).to eq(github_uri)
      end
    end

    context "with bitbucket gems" do
      it "warns about removal" do
        allow(Bundler.ui).to receive(:deprecate)
        msg = "The :bitbucket git source is deprecated, and will be removed " \
          "in Bundler 2.0. Add this code to your Gemfile to ensure it " \
          "continues to work:\n    git_source(:bitbucket) do |repo_name|\n  " \
          "    https://\#{user_name}@bitbucket.org/\#{user_name}/\#{repo_name}" \
          ".git\n    end"
        expect(Bundler.ui).to receive(:deprecate).with(msg, true)
        subject.gem("not-really-a-gem", :bitbucket => "mcorp/flatlab-rails")
      end
    end

    context "with gist gems" do
      it "warns about removal" do
        allow(Bundler.ui).to receive(:deprecate)
        msg = "The :gist git source is deprecated, and will be removed " \
          "in Bundler 2.0. Add this code to your Gemfile to ensure it " \
          "continues to work:\n    git_source(:gist) do |repo_name|\n  " \
          "    https://gist.github.com/\#{repo_name}.git\n" \
          "    end"
        expect(Bundler.ui).to receive(:deprecate).with(msg, true)
        subject.gem("not-really-a-gem", :gist => "1234")
      end
    end
  end
end
