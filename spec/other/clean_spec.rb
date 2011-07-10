require "spec_helper"

describe "bundle clean" do
  def should_have_gems(*gems)
    gems.each do |g|
      vendored_gems("gems/#{g}").should exist
      vendored_gems("specifications/#{g}.gemspec").should exist
      vendored_gems("cache/#{g}.gem").should exist
    end
  end

  def should_not_have_gem(rubygem)
    vendored_gems("gems/#{rubygem}").should_not exist
    vendored_gems("specifications/#{rubygem}.gemspec").should_not exist
    vendored_gems("cache/#{rubygem}.gem").should_not exist
  end

  it "removes unused gems that are different" do
    gemfile = <<-G
      source "file://#{gem_repo1}"

      gem "thin"
      gem "foo"
    G

    install_gemfile(gemfile, :path => "vendor/bundle")

    install_gemfile <<-G
      source "file://#{gem_repo1}"

      gem "thin"
    G

    bundle :clean

    out.should == "Removing foo (1.0)"

    should_have_gems 'thin-1.0', 'rack-1.0.0'
    should_not_have_gem 'foo-1.0'

    vendored_gems("bin/rackup").should exist
  end

  it "removes old version of gem if unused" do
    gemfile = <<-G
      source "file://#{gem_repo1}"

      gem "rack", "0.9.1"
      gem "foo"
    G

    install_gemfile(gemfile, :path => "vendor/bundle")

    install_gemfile <<-G
      source "file://#{gem_repo1}"

      gem "rack", "1.0.0"
      gem "foo"
    G

    bundle :clean

    out.should == "Removing rack (0.9.1)"

    should_have_gems 'foo-1.0', 'rack-1.0.0'
    should_not_have_gem 'rack-0.9.1'

    vendored_gems("bin/rackup").should exist
  end

  it "removes new version of gem if unused" do
    gemfile = <<-G
      source "file://#{gem_repo1}"

      gem "rack", "1.0.0"
      gem "foo"
    G

    install_gemfile(gemfile, :path => "vendor/bundle")

    install_gemfile <<-G
      source "file://#{gem_repo1}"

      gem "rack", "0.9.1"
      gem "foo"
    G

    bundle :clean

    out.should == "Removing rack (1.0.0)"

    should_have_gems 'foo-1.0', 'rack-0.9.1'
    should_not_have_gem 'rack-1.0.0'

    vendored_gems("bin/rackup").should exist
  end

  it "remove gems in bundle without groups" do
    gemfile = <<-G
      source "file://#{gem_repo1}"

      gem "foo"

      group :test_group do
        gem "rack", "1.0.0"
      end
    G

    install_gemfile(gemfile, :path => "vendor/bundle")
    bundle "install --without test_group"
    bundle :clean

    out.should == "Removing rack (1.0.0)"

    should_have_gems 'foo-1.0'
    should_not_have_gem 'rack-1.0.0'

    vendored_gems("bin/rackup").should_not exist
  end

  it "removes unused git gems" do
    build_git "foo"
    @revision = revision_for(lib_path("foo-1.0"))

    gemfile = <<-G
      source "file://#{gem_repo1}"

      gem "rack", "1.0.0"
      git "#{lib_path('foo-1.0')}", :ref => "#{@revision}" do
        gem "foo"
      end
    G

    install_gemfile(gemfile, :path => "vendor/bundle")

    install_gemfile <<-G
      source "file://#{gem_repo1}"

      gem "rack", "1.0.0"
    G

    bundle :clean

    out.should == "Removing foo (1.0 #{@revision[0..11]})"

    vendored_gems("gems/rack-1.0.0").should exist
    vendored_gems("bundler/gems/foo-1.0-#{@revision[0..11]}").should_not exist

    vendored_gems("specifications/rack-1.0.0.gemspec").should exist

    vendored_gems("bin/rackup").should exist
  end

  it "removes old git gems" do
    build_git "foo"
    revision = revision_for(lib_path("foo-1.0"))

    gemfile = <<-G
      source "file://#{gem_repo1}"

      gem "rack", "1.0.0"
      git "#{lib_path('foo-1.0')}" do
        gem "foo"
      end
    G

    install_gemfile(gemfile, :path => "vendor/bundle")

    update_git "foo"
    revision2 = revision_for(lib_path("foo-1.0"))

    bundle :update
    bundle :install
    bundle :clean

    out.should == "Removing foo (1.0 #{revision[0..11]})"

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

    bundle :clean

    out.should == "Can only use bundle clean when --path is set"
  end
end
