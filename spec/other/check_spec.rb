require "spec_helper"

describe "bundle check" do
  it "returns success when the Gemfile is satisfied" do
    install_gemfile <<-G
      source "file://#{gem_repo1}"
      gem "rails"
    G

    bundle :check, :exit_status => true
    check @exitstatus.should == 0
    out.should == "The Gemfile's dependencies are satisfied"
  end

  it "shows what is missing with the current Gemfile if it is not satisfied" do
    gemfile <<-G
      source "file://#{gem_repo1}"
      gem "rails"
    G

    bundle :check, :exit_status => true
    check @exitstatus.should > 0
    out.should include("rails (>= 0, runtime)")
  end

  it "shows missing child dependencies" do
    system_gems "missing_dep-1.0"
    gemfile <<-G
      gem "missing_dep"
    G

    bundle :check
    out.should include('not_here (>= 0, runtime) not found in any of the sources')
    out.should include('required by missing_dep (>= 0, runtime)')
  end

  it "provides debug information when there is a resolving problem" do
    install_gemfile <<-G
      source "file://#{gem_repo1}"
      gem 'rails'
    G
    install_gemfile <<-G
      source "file://#{gem_repo1}"
      gem 'rails_fail'
    G

    gemfile <<-G
      source "file://#{gem_repo1}"
      gem "rails"
      gem "rails_fail"
    G

    bundle :check
    out.should include('Conflict on: "activesupport"')
  end

  it "remembers --without option from install" do
    gemfile <<-G
      source "file://#{gem_repo1}"
      group :foo do
        gem "rack"
      end
    G

    bundle "install --without foo"
    bundle "check", :exit_status => true
    check @exitstatus.should == 0
    out.should include("The Gemfile's dependencies are satisfied")
  end

  it "ensures that gems are actually installed and not just cached" do
    gemfile <<-G
      source "file://#{gem_repo1}"
      gem "rack", :group => :foo
    G

    bundle "install --without foo"

    gemfile <<-G
      source "file://#{gem_repo1}"
      gem "rack"
    G

    bundle "check", :exit_status => true
    out.should include("rack (1.0.0) is cached, but not installed")
    @exitstatus.should == 1
  end

  it "ignores missing gems restricted to other platforms" do
    pending
    system_gems "rack-1.0.0"

    gemfile <<-G
      source "file://#{gem_repo1}"
      gem "rack"
      platforms :#{not_local_tag} do
        gem "activesupport"
      end
    G

    lockfile <<-G
      GEM
        remote: file:#{gem_repo1}/
        specs:
          activesupport (2.3.5)
          rack (1.0.0)

      PLATFORMS
        #{local}
        #{not_local}

      DEPENDENCIES
        rack
        activesupport
    G

    bundle :check
    puts out
    out.should == "The Gemfile's dependencies are satisfied"
  end

  it "works with env conditionals" do
    pending
  end

  it "outputs an error when the default Gemfile is not found" do
    bundle :check, :exit_status => true
    check @exitstatus.should == 10
    out.should include("Could not locate Gemfile")
  end

  it "should not crash when called multiple times on a new machine" do
    gemfile <<-G
    gem 'rails', '3.0.0.beta3'
    gem 'paperclip', :git => 'git://github.com/thoughtbot/paperclip.git'
    G

    simulate_new_machine
    10.times do
      bundle :check
      @err.should == ""
    end
  end

  it "should return the same result when called multiple times on a new machine" do
    gemfile <<-G
    gem 'rails', '3.0.0.beta3'
    gem 'haml'
    G

    simulate_new_machine
    bundle :check
    last_out = @out
    bundle :check
    @out.should == last_out
  end

  describe "when locked" do
    before :each do
      system_gems "rack-1.0.0"
      install_gemfile <<-G
        source "file://#{gem_repo1}"
        gem "rack", "1.0"
      G
    end

    it "returns success when the Gemfile is satisfied" do
      bundle :install
      bundle :check, :exit_status => true
      check @exitstatus.should == 0
      out.should == "The Gemfile's dependencies are satisfied"
    end

    it "shows what is missing with the current Gemfile if it is not satisfied" do
      simulate_new_machine
      bundle :check
      out.should match(/The following dependencies are missing/)
      out.should include("rack (= 1.0")
    end
  end
end
