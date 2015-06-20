require "spec_helper"

describe "Bundler.setup_friendly" do
  # install_gemfile in before(:each) block won't take an RSpec let argument,
  # which I need, because the last example's Gemfile is different
  describe "with no arguments" do
    it "makes all groups available" do
      install_gemfile <<-G
        source "file://#{gem_repo1}"
        gem "rack", :group => :test
      G

      ruby <<-RUBY
        require 'rubygems'
        require 'bundler/setup_friendly'
        Bundler.setup_friendly

        require 'rack'
        puts RACK
      RUBY
      expect(err).to eq("")
      expect(out).to eq("1.0.0")
    end

    it "adds Bundler itself to the load path" do
      install_gemfile <<-G
        source "file://#{gem_repo1}"
        gem "rack", :group => :test
      G

      ruby <<-RUBY
        require 'rubygems'
        require 'bundler/setup_friendly'
        Bundler.setup_friendly
      RUBY
      expect($LOAD_PATH.first).to eq(File.expand_path '../../../lib', __FILE__) # dunno
    end

    it "prints friendly errors" do
      Dir.mktmpdir do |tmp_dir|
        with_gem_path_as tmp_dir do
          gemfile <<-G
            source "file://#{gem_repo1}"
            gem "rack", :group => :test
          G

          ruby <<-RUBY
            require 'rubygems'
            require 'bundler/setup_friendly'
            Bundler.setup_friendly
          RUBY
          expect(out).to include('Could not find rack')
          expect(out).to include('Run `bundle install` to install missing gems.')
        end
      end
    end
  end
end
