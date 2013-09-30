require "spec_helper"

describe "bundle update" do
  it "prints a message" do
    bundle "update"
    expect(out).to include("Are you sure you want to update every single gem in your bundle?!\n\nIf yes, run bundle update --all.\nIf you want to update an individual gem, run bundle update <gem_name>.\nIf not, have a good day!")
  end

  it "does not print bundle was updated" do
    bundle "update"
    expect(out).to_not include("Your bundle is updated!")
  end
end

describe "bundle update --all" do
  before :each do
    build_repo2

    install_gemfile <<-G
      source "file://#{gem_repo2}"
      gem "activesupport"
      gem "rack-obama"
    G
  end

  describe "with no arguments" do
    it "prints --force message and exits" do
      update_repo2 do
        build_gem "activesupport", "3.0"
      end

      bundle "update"
      expect(out).to include("--force")

      should_be_installed "rack 1.0.0", "rack-obama 1.0", "activesupport 2.3.5"
    end

  end

  describe "with --force and no arguments" do
    it "updates the entire bundle" do
      update_repo2 do
        build_gem "activesupport", "3.0"
      end

      bundle "update --force"
      should_be_installed "rack 1.2", "rack-obama 1.0", "activesupport 3.0"
    end

    it "doesn't delete the Gemfile.lock file if something goes wrong" do
      gemfile <<-G
        source "file://#{gem_repo2}"
        gem "activesupport"
        gem "rack-obama"
        exit!
      G
      bundle "update --force"
      expect(bundled_app("Gemfile.lock")).to exist
    end
  end

  describe "--quiet argument" do
    it "shows UI messages without --quiet argument" do
      bundle "update --force"
      expect(out).to include("Fetching source")
    end

    it "does not show UI messages with --quiet argument" do
      bundle "update --quiet --force"
      expect(out).not_to include("Fetching source")
    end
  end

  describe "with a top level dependency" do
    it "unlocks all child dependencies that are unrelated to other locked dependencies" do
      update_repo2 do
        build_gem "activesupport", "3.0"
      end

      bundle "update rack-obama "
      should_be_installed "rack 1.2", "rack-obama 1.0", "activesupport 2.3.5"
    end
  end

  describe "with an unknown dependency" do
    it "should inform the user" do
      bundle "update halting-problem-solver", :expect_err=>true
      expect(out).to include "Could not find gem 'halting-problem-solver'"
    end
    it "should suggest alternatives" do
      bundle "update active-support", :expect_err=>true
      expect(out).to include "Did you mean activesupport?"
    end
  end

  describe "with a child dependency" do
    it "should update the child dependency" do
      update_repo2
      bundle "update rack"
      should_be_installed "rack 1.2"
    end
  end

  describe "with --local option" do
    it "doesn't hit repo2" do
      FileUtils.rm_rf(gem_repo2)

      bundle "update --local"
      expect(out).not_to match(/Fetching source index/)
    end
  end
end

describe "bundle update in more complicated situations" do
  before :each do
    build_repo2
  end

  it "will eagerly unlock dependencies of a specified gem" do
    install_gemfile <<-G
      source "file://#{gem_repo2}"

      gem "thin"
      gem "rack-obama"
    G

    update_repo2 do
      build_gem "thin" , '2.0' do |s|
        s.add_dependency "rack"
      end
    end

    bundle "update thin"
    should_be_installed "thin 2.0", "rack 1.2", "rack-obama 1.0"
  end
end

describe "bundle update without a Gemfile.lock" do
  it "should not explode" do
    build_repo2

    gemfile <<-G
      source "file://#{gem_repo2}"

      gem "rack", "1.0"
    G

    bundle "update --force"

    should_be_installed "rack 1.0.0"
  end
end

describe "bundle update when a gem depends on a newer version of bundler" do
  before(:each) do
    build_repo2 do
      build_gem "rails", "3.0.1" do |s|
        s.add_dependency "bundler", Bundler::VERSION.succ
      end
    end

    gemfile <<-G
      source "file://#{gem_repo2}"
      gem "rails", "3.0.1"
    G
  end

  it "should not explode" do
    bundle "update --force"
    expect(err).to be_empty
  end

  it "should explain that bundler conflicted" do
    bundle "update --force"
    expect(out).not_to match(/in snapshot/i)
    expect(out).to match(/current Bundler version/i)
    expect(out).to match(/perhaps you need to update bundler/i)
  end
end
