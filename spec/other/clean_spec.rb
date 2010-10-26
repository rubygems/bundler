require "spec_helper"

shared_examples_for "bundle clean" do
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

    bundle_command

    out.should include("Removing foo (1.0)")

    vendored_gems("gems/thin-1.0").should exist
    vendored_gems("gems/rack-1.0.0").should exist
    vendored_gems("gems/foo-1.0").should_not exist

    vendored_gems("specifications/thin-1.0.gemspec").should exist
    vendored_gems("specifications/rack-1.0.0.gemspec").should exist
    vendored_gems("specifications/foo-1.0.gemspec").should_not exist

    vendored_gems("bin/rackup").should exist
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

    bundle_command

    out.should include("Removing rack (0.9.1)")

    vendored_gems("gems/foo-1.0").should exist
    vendored_gems("gems/rack-1.0.0").should exist
    vendored_gems("gems/rack-0.9.1").should_not exist

    vendored_gems("specifications/foo-1.0.gemspec").should exist
    vendored_gems("specifications/rack-1.0.0.gemspec").should exist
    vendored_gems("specifications/rack-0.9.1.gemspec").should_not exist

    vendored_gems("bin/rackup").should exist
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

    bundle_command

    out.should include("Removing rack (1.0.0)")

    vendored_gems("gems/foo-1.0").should exist
    vendored_gems("gems/rack-0.9.1").should exist
    vendored_gems("gems/rack-1.0.0").should_not exist

    vendored_gems("specifications/foo-1.0.gemspec").should exist
    vendored_gems("specifications/rack-0.9.1.gemspec").should exist
    vendored_gems("specifications/rack-1.0.0.gemspec").should_not exist

    vendored_gems("bin/rackup").should exist
  end

  it "removes unused git gems" do
    build_git "foo"
    @revision = revision_for(lib_path("foo-1.0"))

    install_gemfile <<-G
      source "file://#{gem_repo1}"

      gem "rack", "1.0.0"
      git "#{lib_path('foo-1.0')}", :ref => "#{@revision}" do
        gem "foo"
      end
    G

    bundle "install --path vendor"

    install_gemfile <<-G
      source "file://#{gem_repo1}"

      gem "rack", "1.0.0"
    G

    bundle_command

    out.should include("Removing foo (1.0 #{@revision[0..11]})")

    vendored_gems("gems/rack-1.0.0").should exist
    vendored_gems("bundler/gems/foo-1.0-#{@revision[0..11]}").should_not exist

    vendored_gems("specifications/rack-1.0.0.gemspec").should exist

    vendored_gems("bin/rackup").should exist
  end

  it "removes old git gems" do
    build_git "foo"
    revision = revision_for(lib_path("foo-1.0"))

    install_gemfile <<-G
      source "file://#{gem_repo1}"

      gem "rack", "1.0.0"
      git "#{lib_path('foo-1.0')}" do
        gem "foo"
      end
    G

    bundle "install --path vendor"

    update_git "foo"
    revision2 = revision_for(lib_path("foo-1.0"))

    bundle :update
    bundle_command

    out.should include("Removing foo (1.0 #{revision[0..11]})")

    vendored_gems("gems/rack-1.0.0").should exist
    vendored_gems("bundler/gems/foo-1.0-#{revision[0..11]}").should_not exist
    vendored_gems("bundler/gems/foo-1.0-#{revision2[0..11]}").should exist

    vendored_gems("specifications/rack-1.0.0.gemspec").should exist

    vendored_gems("bin/rackup").should exist
  end

  it "displays an error when used without --path" do
    install_gemfile <<-G
      source "file://#{gem_repo1}"

      gem "rack", "1.0.0"
    G

    bundle_command

    out.should include("Can only use bundle clean when --path is set")
  end
end

share_examples_for "bundle clean without groups" do
  it "remove gems in bundle without groups" do
    install_gemfile <<-G
      source "file://#{gem_repo1}"

      gem "foo"

      group :test_group do
        gem "rack", "1.0.0"
      end
    G

    bundle "install --path vendor"
    bundle_command

    out.should include("Removing rack (1.0.0)")

    vendored_gems("gems/foo-1.0").should exist
    vendored_gems("gems/rack-1.0.0").should_not exist

    vendored_gems("specifications/foo-1.0.gemspec").should exist
    vendored_gems("specifications/rack-1.0.0.gemspec").should_not exist

    vendored_gems("bin/rackup").should_not exist
  end
end

describe "clean" do
  describe "bundle clean" do
    def bundle_command
      bundle :install
      bundle :clean
    end

    it_behaves_like "bundle clean"

    context "without groups" do
      def bundle_command
        bundle "install --without test_group"
        bundle :clean
      end

      it_behaves_like "bundle clean without groups"
    end
  end

  describe "bundle install --clean" do
    def bundle_command
      bundle "install --clean"
    end

    it_behaves_like "bundle clean"

    context "without groups" do
      def bundle_command
        bundle "install --clean --without test_group"
      end

      it_behaves_like "bundle clean without groups"
    end
  end
end
