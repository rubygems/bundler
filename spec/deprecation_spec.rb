# frozen_string_literal: true
require "spec_helper"

describe "Bundler version 1.99" do
  context "when bundle is run" do
    it "should print a single deprecation warning" do
      # install_gemfile calls `bundle :install, opts`
      install_gemfile <<-G
        source "file://#{gem_repo1}"
        gem "rack"
      G

      expect(err).to eq("DEPRECATION: Gemfile and Gemfile.lock are " \
       "deprecated and will be replaced with gems.rb and gems.locked in " \
       "Bundler 2.0.0.")
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
       "Bundler 2.0.0.")
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
end
