require "spec_helper"

describe "install with --deployment or --frozen" do
  before do
    gemfile <<-G
      source "file://#{gem_repo1}"
      gem "rack"
    G
  end

  it "fails without a lockfile and says that --deployment requires a lock" do
    bundle "install --deployment"
    out.should include("The --deployment flag requires a Gemfile.lock")
  end

  it "fails without a lockfile and says that --frozen requires a lock" do
    bundle "install --frozen"
    out.should include("The --frozen flag requires a Gemfile.lock")
  end

  it "works after you try to deploy without a lock" do
    bundle "install --deployment"
    bundle :install, :exitstatus => true
    exitstatus.should eq(0)
    should_be_installed "rack 1.0"
  end

  it "still works if you are not in the app directory and specify --gemfile" do
    bundle "install"
    Dir.chdir tmp
    simulate_new_machine
    bundle "install --gemfile #{tmp}/bundled_app/Gemfile --deployment"
    Dir.chdir bundled_app
    should_be_installed "rack 1.0"
  end

  it "works if you exclude a group with a git gem" do
    build_git "foo"
    gemfile <<-G
      group :test do
        gem "foo", :git => "#{lib_path('foo-1.0')}"
      end
    G
    bundle :install
    bundle "install --deployment --without test", :exitstatus => true
    exitstatus.should == 0
  end

  it "works when you bundle exec bundle" do
    bundle :install
    bundle "install --deployment"
    bundle "exec bundle check", :exitstatus => true
    exitstatus.should == 0
  end

  describe "with an existing lockfile" do
    before do
      bundle "install"
    end

    it "works with the --deployment flag if you didn't change anything" do
      bundle "install --deployment", :exitstatus => true
      exitstatus.should == 0
    end

    it "works with the --frozen flag if you didn't change anything" do
      bundle "install --frozen", :exitstatus => true
      exitstatus.should == 0
    end

    it "explodes with the --deployment flag if you make a change and don't check in the lockfile" do
      gemfile <<-G
        source "file://#{gem_repo1}"
        gem "rack"
        gem "rack-obama"
      G

      bundle "install --deployment"
      out.should include("deployment mode")
      out.should include("You have added to the Gemfile")
      out.should include("* rack-obama")
      out.should_not include("You have deleted from the Gemfile")
      out.should_not include("You have changed in the Gemfile")
    end

    it "can have --frozen set via an environment variable" do
      gemfile <<-G
        source "file://#{gem_repo1}"
        gem "rack"
        gem "rack-obama"
      G

      ENV['BUNDLE_FROZEN'] = '1'
      bundle "install"
      out.should include("deployment mode")
      out.should include("You have added to the Gemfile")
      out.should include("* rack-obama")
      out.should_not include("You have deleted from the Gemfile")
      out.should_not include("You have changed in the Gemfile")
    end

    it "explodes with the --frozen flag if you make a change and don't check in the lockfile" do
      gemfile <<-G
        source "file://#{gem_repo1}"
        gem "rack"
        gem "rack-obama"
      G

      bundle "install --frozen"
      out.should include("deployment mode")
      out.should include("You have added to the Gemfile")
      out.should include("* rack-obama")
      out.should_not include("You have deleted from the Gemfile")
      out.should_not include("You have changed in the Gemfile")
    end

    it "explodes if you remove a gem and don't check in the lockfile" do
      gemfile <<-G
        source "file://#{gem_repo1}"
        gem "activesupport"
      G

      bundle "install --deployment"
      out.should include("deployment mode")
      out.should include("You have added to the Gemfile:\n* activesupport\n\n")
      out.should include("You have deleted from the Gemfile:\n* rack")
      out.should_not include("You have changed in the Gemfile")
    end

    it "explodes if you add a source" do
      gemfile <<-G
        source "file://#{gem_repo1}"
        gem "rack", :git => "git://hubz.com"
      G

      bundle "install --deployment"
      out.should include("deployment mode")
      out.should include("You have added to the Gemfile:\n* source: git://hubz.com (at master)")
      out.should_not include("You have changed in the Gemfile")
    end

    it "explodes if you unpin a source" do
      build_git "rack"

      install_gemfile <<-G
        source "file://#{gem_repo1}"
        gem "rack", :git => "#{lib_path("rack-1.0")}"
      G

      gemfile <<-G
        source "file://#{gem_repo1}"
        gem "rack"
      G

      bundle "install --deployment"
      out.should include("deployment mode")
      out.should include("You have deleted from the Gemfile:\n* source: #{lib_path("rack-1.0")} (at master)")
      out.should_not include("You have added to the Gemfile")
      out.should_not include("You have changed in the Gemfile")
    end

    it "explodes if you unpin a source, leaving it pinned somewhere else" do
      build_lib "foo", :path => lib_path("rack/foo")
      build_git "rack", :path => lib_path("rack")

      install_gemfile <<-G
        source "file://#{gem_repo1}"
        gem "rack", :git => "#{lib_path("rack")}"
        gem "foo", :git => "#{lib_path("rack")}"
      G

      gemfile <<-G
        source "file://#{gem_repo1}"
        gem "rack"
        gem "foo", :git => "#{lib_path("rack")}"
      G

      bundle "install --deployment"
      out.should include("deployment mode")
      out.should include("You have changed in the Gemfile:\n* rack from `no specified source` to `#{lib_path("rack")} (at master)`")
      out.should_not include("You have added to the Gemfile")
      out.should_not include("You have deleted from the Gemfile")
    end

    it "remembers that the bundle is frozen at runtime" do
      bundle "install --deployment"

      gemfile <<-G
        source "file://#{gem_repo1}"
        gem "rack", "1.0.0"
        gem "rack-obama"
      G

      should_be_installed "rack 1.0.0"
    end
  end
end
