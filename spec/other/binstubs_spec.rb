require "spec_helper"

describe "bundle binstubs <gem>" do
  context "when the gem exists in the lockfile" do
    it "sets up the binstub" do
      install_gemfile <<-G
        source "file://#{gem_repo1}"
        gem "rack"
      G

      bundle "binstubs rack"

      expect(bundled_app("bin/rackup")).to exist
    end

    it "does not install other binstubs" do
      install_gemfile <<-G
        source "file://#{gem_repo1}"
        gem "rack"
        gem "rails"
      G

      bundle "binstubs rails"

      expect(bundled_app("bin/rackup")).not_to exist
      expect(bundled_app("bin/rails")).to exist
    end

    it "does not bundle the bundler binary" do
      install_gemfile <<-G
        source "file://#{gem_repo1}"
      G

      bundle "binstubs bundler"

      expect(bundled_app("bin/bundle")).not_to exist
    end

    it "install binstubs from git gems" do
      FileUtils.mkdir_p(lib_path("foo/bin"))
      FileUtils.touch(lib_path("foo/bin/foo"))
      build_git "foo", "1.0", :path => lib_path("foo") do |s|
        s.executables = %w(foo)
      end
      install_gemfile <<-G
        gem "foo", :git => "#{lib_path('foo')}"
      G

      bundle "binstubs foo"

      expect(bundled_app("bin/foo")).to exist
    end

    it "installs binstubs from path gems" do
      FileUtils.mkdir_p(lib_path("foo/bin"))
      FileUtils.touch(lib_path("foo/bin/foo"))
      build_lib "foo" , "1.0", :path => lib_path("foo") do |s|
        s.executables = %w(foo)
      end
      install_gemfile <<-G
        gem "foo", :path => "#{lib_path('foo')}"
      G

      bundle "binstubs foo"

      expect(bundled_app("bin/foo")).to exist
    end
  end
end
