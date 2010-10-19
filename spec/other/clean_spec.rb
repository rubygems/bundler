require "spec_helper"

describe "bundle clean" do
  it "removes unused gems that are different" do
    install_gemfile <<-G
      source "file://#{gem_repo1}"

      gem "thin"
      gem "foo"
    G

    bundle "install --path vendor"

    install_gemfile <<-G
      source "file://#{gem_repo1}"

      gem "thin"
    G

    bundle :install
    bundle :clean

    out.should == "Removing foo (1.0)"

    vendored_gems("gems/thin-1.0").should exist
    vendored_gems("gems/rack-1.0.0").should exist
    vendored_gems("gems/foo-1.0").should_not exist

    vendored_gems("specifications/thin-1.0.gemspec").should exist
    vendored_gems("specifications/rack-1.0.0.gemspec").should exist
    vendored_gems("specifications/foo-1.0.gemspec").should_not exist
  end

  it "removes old version of gem if unused" do
    install_gemfile <<-G
      source "file://#{gem_repo1}"

      gem "rack", "0.9.1"
      gem "foo"
    G

    bundle "install --path vendor"

    install_gemfile <<-G
      source "file://#{gem_repo1}"

      gem "rack", "1.0.0"
      gem "foo"
    G

    bundle :install
    bundle :clean

    out.should == "Removing rack (0.9.1)"

    vendored_gems("gems/foo-1.0").should exist
    vendored_gems("gems/rack-1.0.0").should exist
    vendored_gems("gems/rack-0.9.1").should_not exist

    vendored_gems("specifications/foo-1.0.gemspec").should exist
    vendored_gems("specifications/rack-1.0.0.gemspec").should exist
    vendored_gems("specifications/rack-0.9.1.gemspec").should_not exist
  end

  it "removes new version of gem if unused" do
    install_gemfile <<-G
      source "file://#{gem_repo1}"

      gem "rack", "1.0.0"
      gem "foo"
    G

    bundle "install --path vendor"

    install_gemfile <<-G
      source "file://#{gem_repo1}"

      gem "rack", "0.9.1"
      gem "foo"
    G

    bundle :install
    bundle :clean

    out.should == "Removing rack (1.0.0)"

    vendored_gems("gems/foo-1.0").should exist
    vendored_gems("gems/rack-0.9.1").should exist
    vendored_gems("gems/rack-1.0.0").should_not exist

    vendored_gems("specifications/foo-1.0.gemspec").should exist
    vendored_gems("specifications/rack-0.9.1.gemspec").should exist
    vendored_gems("specifications/rack-1.0.0.gemspec").should_not exist
  end

  it "remove gems in bundle without groups" do
    install_gemfile <<-G
      source "file://#{gem_repo1}"

      gem "foo"

      group :test_group do
        gem "rack", "1.0.0"
      end
    G

    bundle "install --path vendor"
    bundle "install --without test_group"
    bundle :clean

    out.should == "Removing rack (1.0.0)"

    vendored_gems("gems/foo-1.0").should exist
    vendored_gems("gems/rack-1.0.0").should_not exist

    vendored_gems("specifications/foo-1.0.gemspec").should exist
    vendored_gems("specifications/rack-1.0.0.gemspec").should_not exist
  end

  it "removes out of date git gems"

  it "throws an error when used without --path"
end
