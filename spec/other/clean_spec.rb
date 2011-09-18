require "spec_helper"

describe "bundle clean" do
  def should_have_gems(*gems)
    gems.each do |g|
      vendored_gems("gems/#{g}").should exist
      vendored_gems("specifications/#{g}.gemspec").should exist
      vendored_gems("cache/#{g}.gem").should exist
    end
  end

  def should_not_have_gems(*gems)
    gems.each do |g|
      vendored_gems("gems/#{g}").should_not exist
      vendored_gems("specifications/#{g}.gemspec").should_not exist
      vendored_gems("cache/#{g}.gem").should_not exist
    end
  end

  it "removes unused gems that are different" do
    gemfile <<-G
      source "file://#{gem_repo1}"

      gem "thin"
      gem "foo"
    G

    bundle "install --path vendor/bundle --no-clean"

    gemfile <<-G
      source "file://#{gem_repo1}"

      gem "thin"
    G
    bundle "install --no-clean"

    bundle :clean

    out.should eq("Removing foo (1.0)")

    should_have_gems 'thin-1.0', 'rack-1.0.0'
    should_not_have_gems 'foo-1.0'

    vendored_gems("bin/rackup").should exist
  end

  it "removes old version of gem if unused" do
    gemfile <<-G
      source "file://#{gem_repo1}"

      gem "rack", "0.9.1"
      gem "foo"
    G

    bundle "install --path vendor/bundle --no-clean"

    gemfile <<-G
      source "file://#{gem_repo1}"

      gem "rack", "1.0.0"
      gem "foo"
    G
    bundle "install --no-clean"

    bundle :clean

    out.should eq("Removing rack (0.9.1)")

    should_have_gems 'foo-1.0', 'rack-1.0.0'
    should_not_have_gems 'rack-0.9.1'

    vendored_gems("bin/rackup").should exist
  end

  it "removes new version of gem if unused" do
    gemfile <<-G
      source "file://#{gem_repo1}"

      gem "rack", "1.0.0"
      gem "foo"
    G

    bundle "install --path vendor/bundle --no-clean"

    gemfile <<-G
      source "file://#{gem_repo1}"

      gem "rack", "0.9.1"
      gem "foo"
    G
    bundle "install --no-clean"

    bundle :clean

    out.should eq("Removing rack (1.0.0)")

    should_have_gems 'foo-1.0', 'rack-0.9.1'
    should_not_have_gems 'rack-1.0.0'

    vendored_gems("bin/rackup").should exist
  end

  it "remove gems in bundle without groups" do
    gemfile <<-G
      source "file://#{gem_repo1}"

      gem "foo"

      group :test_group do
        gem "rack", "1.0.0"
      end
    G

    bundle "install --path vendor/bundle --no-clean"
    bundle "install --without test_group --no-clean"
    bundle :clean

    out.should eq("Removing rack (1.0.0)")

    should_have_gems 'foo-1.0'
    should_not_have_gems 'rack-1.0.0'

    vendored_gems("bin/rackup").should_not exist
  end

  it "does not remove cached git dir if it's being used" do
    build_git "foo"
    revision = revision_for(lib_path("foo-1.0"))
    git_path = lib_path('foo-1.0')

    gemfile <<-G
      source "file://#{gem_repo1}"

      gem "rack", "1.0.0"
      git "#{git_path}", :ref => "#{revision}" do
        gem "foo"
      end
    G

    bundle "install --path vendor/bundle --no-clean"

    bundle :clean

    digest = Digest::SHA1.hexdigest(git_path.to_s)
    vendored_gems("cache/bundler/git/foo-1.0-#{digest}").should exist
  end

  it "removes unused git gems" do
    build_git "foo"
    revision = revision_for(lib_path("foo-1.0"))
    git_path = lib_path('foo-1.0')

    gemfile <<-G
      source "file://#{gem_repo1}"

      gem "rack", "1.0.0"
      git "#{git_path}", :ref => "#{revision}" do
        gem "foo"
      end
    G

    bundle "install --path vendor/bundle --no-clean"

    gemfile <<-G
      source "file://#{gem_repo1}"

      gem "rack", "1.0.0"
    G
    bundle "install --no-clean"

    bundle :clean

    out.should eq("Removing foo (1.0 #{revision[0..11]})")

    vendored_gems("gems/rack-1.0.0").should exist
    vendored_gems("bundler/gems/foo-1.0-#{revision[0..11]}").should_not exist
    digest = Digest::SHA1.hexdigest(git_path.to_s)
    vendored_gems("cache/bundler/git/foo-1.0-#{digest}").should_not exist

    vendored_gems("specifications/rack-1.0.0.gemspec").should exist

    vendored_gems("bin/rackup").should exist
  end

  it "removes old git gems" do
    build_git "foo"
    revision = revision_for(lib_path("foo-1.0"))

    gemfile <<-G
      source "file://#{gem_repo1}"

      gem "rack", "1.0.0"
      git "#{lib_path('foo-1.0')}" do
        gem "foo"
      end
    G

    bundle "install --path vendor/bundle --no-clean"

    update_git "foo"
    revision2 = revision_for(lib_path("foo-1.0"))

    bundle "update --no-clean"
    bundle :clean

    out.should eq("Removing foo (1.0 #{revision[0..11]})")

    vendored_gems("gems/rack-1.0.0").should exist
    vendored_gems("bundler/gems/foo-1.0-#{revision[0..11]}").should_not exist
    vendored_gems("bundler/gems/foo-1.0-#{revision2[0..11]}").should exist

    vendored_gems("specifications/rack-1.0.0.gemspec").should exist

    vendored_gems("bin/rackup").should exist
  end

  it "does not remove nested gems in a git repo" do
    build_lib "activesupport", "3.0", :path => lib_path("rails/activesupport")
    build_git "rails", "3.0", :path => lib_path("rails") do |s|
      s.add_dependency "activesupport", "= 3.0"
    end
    revision = revision_for(lib_path("rails"))

    gemfile <<-G
      gem "activesupport", :git => "#{lib_path('rails')}", :ref => '#{revision}'
    G

    bundle "install --path vendor/bundle --no-clean"
    bundle :clean
    out.should eq("")

    vendored_gems("bundler/gems/rails-#{revision[0..11]}").should exist
  end

  it "displays an error when used without --path" do
    install_gemfile <<-G
      source "file://#{gem_repo1}"

      gem "rack", "1.0.0"
    G

    bundle :clean

    out.should == "Can only use bundle clean when --path is set or --force is set"
  end

  # handling bundle clean upgrade path from the pre's
  it "removes .gem/.gemspec file even if there's no corresponding gem dir is already moved" do
    gemfile <<-G
      source "file://#{gem_repo1}"

      gem "thin"
      gem "foo"
    G

    bundle "install --path vendor/bundle --no-clean"

    gemfile <<-G
      source "file://#{gem_repo1}"

      gem "foo"
    G
    bundle "install --no-clean"

    FileUtils.rm(vendored_gems("bin/rackup"))
    FileUtils.rm_rf(vendored_gems("gems/thin-1.0"))
    FileUtils.rm_rf(vendored_gems("gems/rack-1.0.0"))

    bundle :clean

    should_not_have_gems 'thin-1.0', 'rack-1.0'
    should_have_gems 'foo-1.0'

    vendored_gems("bin/rackup").should_not exist
  end

  it "does not call clean automatically when using system gems" do
    gemfile <<-G
      source "file://#{gem_repo1}"

      gem "thin"
      gem "rack"
    G
    bundle :install

    gemfile <<-G
      source "file://#{gem_repo1}"

      gem "rack"
    G
    bundle :install

    sys_exec "gem list"
    out.should include("rack (1.0.0)")
    out.should include("thin (1.0)")
  end

  it "--clean should override the bundle setting" do
    gemfile <<-G
      source "file://#{gem_repo1}"

      gem "thin"
      gem "rack"
    G
    bundle "install --path vendor/bundle --no-clean"

    gemfile <<-G
      source "file://#{gem_repo1}"

      gem "rack"
    G
    bundle "install --clean"

    should_have_gems 'rack-1.0.0'
    should_not_have_gems 'thin-1.0'
  end

  it "clean automatically on --path" do
    gemfile <<-G
      source "file://#{gem_repo1}"

      gem "thin"
      gem "rack"
    G
    bundle "install --path vendor/bundle"

    gemfile <<-G
      source "file://#{gem_repo1}"

      gem "rack"
    G
    bundle "install"

    should_have_gems 'rack-1.0.0'
    should_not_have_gems 'thin-1.0'
  end

  it "cleans on bundle update with --path" do
    build_repo2

    gemfile <<-G
      source "file://#{gem_repo2}"

      gem "foo"
    G
    bundle "install --path vendor/bundle"

    update_repo2 do
      build_gem 'foo', '1.0.1'
    end

    bundle :update
    should_not_have_gems 'foo-1.0'
  end

  it "does not clean on bundle update when using --system" do
    build_repo2

    gemfile <<-G
      source "file://#{gem_repo2}"

      gem "foo"
    G
    bundle "install"

    update_repo2 do
      build_gem 'foo', '1.0.1'
    end
    bundle :update

    sys_exec "gem list"
    out.should include("foo (1.0.1, 1.0)")
  end

  it "cleans system gems when --force is used" do
    gemfile <<-G
      source "file://#{gem_repo1}"

      gem "foo"
      gem "rack"
    G
    bundle :install

    gemfile <<-G
      source "file://#{gem_repo1}"

      gem "rack"
    G
    bundle :install
    bundle "clean --force"

    out.should eq("Removing foo (1.0)")
    sys_exec "gem list"
    out.should_not include("foo (1.0)")
    out.should include("rack (1.0.0)")
  end
end
