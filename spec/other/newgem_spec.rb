require "spec_helper"

describe "bundle gem" do
  before do
    @git_name = `git config --global user.name`.chomp
    `git config --global user.name "Bundler User"`
    @git_email = `git config --global user.email`.chomp
    `git config --global user.email user@example.com`
  end

  after do
    `git config --global user.name "#{@git_name}"`
    `git config --global user.email #{@git_email}`
  end

  shared_examples_for "without git config" do
    it "sets gemspec author to default message if git user.name is not set or empty" do
      generated_gem.gemspec.authors.first.should == "TODO: Write your name"
    end

    it "sets gemspec email to default message if git user.email is not set or empty" do
      generated_gem.gemspec.email.first.should == "TODO: Write your email address"
    end
  end

  context "gem naming with underscore" do
    before :each do
      bundle 'gem test_gem'
      # reset gemspec cache for each test because of commit 3d4163a
      Bundler.clear_gemspec_cache
    end

    let(:generated_gem) { Bundler::GemHelper.new(bundled_app("test_gem").to_s) }

    it "generates a gem skeleton" do
      bundled_app("test_gem/test_gem.gemspec").should exist
      bundled_app("test_gem/LICENSE.txt").should exist
      bundled_app("test_gem/Gemfile").should exist
      bundled_app("test_gem/Rakefile").should exist
      bundled_app("test_gem/lib/test_gem.rb").should exist
      bundled_app("test_gem/lib/test_gem/version.rb").should exist
    end

    it "starts with version 0.0.1" do
      bundled_app("test_gem/lib/test_gem/version.rb").read.should =~ /VERSION = "0.0.1"/
    end

    it "nests constants so they work" do
      bundled_app("test_gem/lib/test_gem/version.rb").read.should =~ /module TestGem/
      bundled_app("test_gem/lib/test_gem.rb").read.should =~ /module TestGem/
    end

    context "git config user.{name,email} present" do
      it "sets gemspec author to git user.name if available" do
        generated_gem.gemspec.authors.first.should == "Bundler User"
      end

      it "sets gemspec email to git user.email if available" do
        generated_gem.gemspec.email.first.should == "user@example.com"
      end
    end

    context "git config user.{name,email} is not set" do
      before :each do
        `git config --global --unset user.name`
        `git config --global --unset user.email`
        reset!
        in_app_root
        bundle 'gem test_gem'
      end

      it_should_behave_like "without git config"
    end

    it "requires the version file" do
      bundled_app("test_gem/lib/test_gem.rb").read.should =~ /require "test_gem\/version"/
    end

    it "runs rake without problems" do
      system_gems ["rake-0.8.7"]

      rakefile = <<-RAKEFILE
        task :default do
          puts 'SUCCESS'
        end
  RAKEFILE
      File.open(bundled_app("test_gem/Rakefile"), 'w') do |file|
        file.puts rakefile
      end

      Dir.chdir(bundled_app("test_gem")) do
        sys_exec("rake")
        out.should include("SUCCESS")
      end
    end
  end

  context "gem naming with dashed" do
    before :each do
      bundle 'gem test-gem'
      # reset gemspec cache for each test because of commit 3d4163a
      Bundler.clear_gemspec_cache
    end

    let(:generated_gem) { Bundler::GemHelper.new(bundled_app("test-gem").to_s) }

    it "generates a gem skeleton" do
      bundled_app("test-gem/test-gem.gemspec").should exist
      bundled_app("test-gem/LICENSE.txt").should exist
      bundled_app("test-gem/Gemfile").should exist
      bundled_app("test-gem/Rakefile").should exist
      bundled_app("test-gem/lib/test/gem.rb").should exist
      bundled_app("test-gem/lib/test/gem/version.rb").should exist
    end

    it "starts with version 0.0.1" do
      bundled_app("test-gem/lib/test/gem/version.rb").read.should =~ /VERSION = "0.0.1"/
    end

    it "nests constants so they work" do
      bundled_app("test-gem/lib/test/gem/version.rb").read.should =~ /module Test\n  module Gem/
      bundled_app("test-gem/lib/test/gem.rb").read.should =~ /module Test\n  module Gem/
    end

    context "git config user.{name,email} present" do
      it "sets gemspec author to git user.name if available" do
        generated_gem.gemspec.authors.first.should == "Bundler User"
      end

      it "sets gemspec email to git user.email if available" do
        generated_gem.gemspec.email.first.should == "user@example.com"
      end
    end

    context "git config user.{name,email} is not set" do
      before :each do
        `git config --global --unset user.name`
        `git config --global --unset user.email`
        reset!
        in_app_root
        bundle 'gem test-gem'
      end

      it_should_behave_like "without git config"
    end

    it "requires the version file" do
      bundled_app("test-gem/lib/test/gem.rb").read.should =~ /require "test\/gem\/version"/
    end

    it "runs rake without problems" do
      system_gems ["rake-0.8.7"]

      rakefile = <<-RAKEFILE
        task :default do
          puts 'SUCCESS'
        end
  RAKEFILE
      File.open(bundled_app("test-gem/Rakefile"), 'w') do |file|
        file.puts rakefile
      end

      Dir.chdir(bundled_app("test-gem")) do
        sys_exec("rake")
        out.should include("SUCCESS")
      end
    end
  end
end
