# frozen_string_literal: true
require "spec_helper"

describe "bundle install" do
  context "git sources" do
    it "displays the revision hash of the gem repository" do
      build_git "foo", "1.0", :path => lib_path("foo")

      install_gemfile <<-G
        gem "foo", :git => "#{lib_path("foo")}"
      G

      bundle :install
      expect(out).to include("Using foo 1.0 from #{lib_path("foo")} (at master@#{revision_for(lib_path("foo"))[0..6]})")
      should_be_installed "foo 1.0"
    end

    it "should check out git repos that are missing but not being installed" do
      build_git "foo"

      gemfile <<-G
        gem "foo", :git =>"file://#{lib_path("foo-1.0")}", group: :development
      G

      lockfile <<-L
        GIT
          remote: file://#{lib_path("foo-1.0")}
          specs:
            foo (1.0)

        PLATFORMS
          ruby

        DEPENDENCIES
          foo!
      L

      bundle "install --path=vendor/bundle --without development"

      expect(out).to include("Bundle complete!")
    end
  end
end
