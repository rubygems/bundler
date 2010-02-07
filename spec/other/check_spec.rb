require File.expand_path('../../spec_helper', __FILE__)

describe "bundle check" do
  before :each do
    in_app_root
  end

  it "returns success when the Gemfile is satisfied" do
    install_gemfile <<-G
      source "file://#{gem_repo1}"
      gem "rails"
    G

    bundle :check
    @exitstatus.should == 0 if @exitstatus
    out.should == "The Gemfile's dependencies are satisfied"
  end

  it "shows what is missing with the current Gemfile if it is not satisfied" do
    gemfile <<-G
      source "file://#{gem_repo1}"
      gem "rails"
    G

    bundle :check
    @exitstatus.should_not == 0 if @exitstatus
    out.should =~ /rails \(>= 0, runtime\)/
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

  it "outputs an error when the default Gemspec is not found" do
    bundle :check
    @exitstatus.should_not == 0 if @exitstatus
    out.should =~ /The default Gemfile was not found/
  end
end
