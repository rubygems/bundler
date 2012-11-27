require "spec_helper"

describe "bundle gem" do
  before :each do
    @git_name = `git config --global user.name`.chomp
    `git config --global user.name "Bundler User"`
    @git_email = `git config --global user.email`.chomp
    `git config --global user.email user@example.com`
    bundle 'gem test-gem'
    # reset gemspec cache for each test because of commit 3d4163a
    Bundler.clear_gemspec_cache
  end

  after :each do
    `git config --global user.name "#{@git_name}"`
    `git config --global user.email #{@git_email}`
  end

  let(:generated_gem) { Bundler::GemHelper.new(bundled_app("test-gem").to_s) }

  it "generates a gem skeleton" do
    expect(bundled_app("test-gem/test-gem.gemspec")).to exist
    expect(bundled_app("test-gem/LICENSE.txt")).to exist
    expect(bundled_app("test-gem/Gemfile")).to exist
    expect(bundled_app("test-gem/Rakefile")).to exist
    expect(bundled_app("test-gem/lib/test-gem.rb")).to exist
    expect(bundled_app("test-gem/lib/test-gem/version.rb")).to exist
  end

  it "starts with version 0.0.1" do
    expect(bundled_app("test-gem/lib/test-gem/version.rb").read).to match(/VERSION = "0.0.1"/)
  end

  it "nests constants so they work" do
    expect(bundled_app("test-gem/lib/test-gem/version.rb").read).to match(/module Test\n  module Gem/)
    expect(bundled_app("test-gem/lib/test-gem.rb").read).to match(/module Test\n  module Gem/)
  end

  context "git config user.{name,email} present" do
    it "sets gemspec author to git user.name if available" do
      expect(generated_gem.gemspec.authors.first).to eq("Bundler User")
    end

    it "sets gemspec email to git user.email if available" do
      expect(generated_gem.gemspec.email.first).to eq("user@example.com")
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

    it "sets gemspec author to default message if git user.name is not set or empty" do
      expect(generated_gem.gemspec.authors.first).to eq("TODO: Write your name")
    end

    it "sets gemspec email to default message if git user.email is not set or empty" do
      expect(generated_gem.gemspec.email.first).to eq("TODO: Write your email address")
    end
  end

  it "sets gemspec license to MIT by default" do
    expect(generated_gem.gemspec.license).to eq("MIT")
  end

  it "requires the version file" do
    expect(bundled_app("test-gem/lib/test-gem.rb").read).to match(/require "test-gem\/version"/)
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
      expect(out).to include("SUCCESS")
    end
  end

  context "--bin parameter set" do
    before :each do
      reset!
      in_app_root
      bundle 'gem test-gem --bin'
    end

    it "builds bin skeleton" do
      expect(bundled_app("test-gem/bin/test-gem")).to exist
    end

    it "requires 'test-gem'" do
      expect(bundled_app("test-gem/bin/test-gem").read).to match(/require 'test-gem'/)
    end
  end

  context "--test parameter set to rspec" do
    before :each do
      reset!
      in_app_root
      bundle "gem test-gem --test=rspec"
    end

    it "builds spec skeleton" do
      expect(bundled_app("test-gem/.rspec")).to exist
      expect(bundled_app("test-gem/spec/test-gem_spec.rb")).to exist
      expect(bundled_app("test-gem/spec/spec_helper.rb")).to exist
    end

    it "requires 'test-gem'" do
      expect(bundled_app("test-gem/spec/spec_helper.rb").read).to match(/require 'test-gem'/)
    end

    it "creates a default test which fails" do
      expect(bundled_app("test-gem/spec/test-gem_spec.rb").read).to match(/false.should be_true/)
    end
  end

  context "--test parameter set to minitest" do
    before :each do
      reset!
      in_app_root
      bundle "gem test-gem --test=minitest"
    end

    it "builds spec skeleton" do
      expect(bundled_app("test-gem/test/test_test-gem.rb")).to exist
      expect(bundled_app("test-gem/test/minitest_helper.rb")).to exist
    end

    it "requires 'test-gem'" do
      expect(bundled_app("test-gem/test/minitest_helper.rb").read).to match(/require 'test-gem'/)
    end

    it "requires 'minitest_helper'" do
      expect(bundled_app("test-gem/test/test_test-gem.rb").read).to match(/require '.\/minitest_helper'/)
    end

    it "creates a default test which fails" do
      expect(bundled_app("test-gem/test/test_test-gem.rb").read).to match(/assert false/)
    end
  end

  context "--test with no arguments" do
    before :each do
      reset!
      in_app_root
      bundle "gem test-gem --test"
    end

    it "defaults to rspec" do
      expect(bundled_app("test-gem/spec/spec_helper.rb")).to exist
      expect(bundled_app("test-gem/test/minitest_helper.rb")).to_not exist
    end
  end
end
