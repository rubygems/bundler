# frozen_string_literal: true
require "spec_helper"
require "fileutils"

RSpec.describe "bundle pristine" do
  before :each do
    build_repo2 do
      build_gem "weakling"
      build_git "foo", :path => lib_path("foo")
      build_lib "bar", :path => lib_path("bar")
    end

    install_gemfile <<-G
      source "file://#{gem_repo2}"
      gem "weakling"
      gem "foo", :git => "#{lib_path("foo")}"
      gem "bar", :path => "#{lib_path("bar")}"
    G

    bundle "install"
  end

  context "when sourced from Rubygems" do
    it "reverts using cached .gem file" do
      spec = Bundler.definition.specs["weakling"].first
      changes_txt = "#{spec.full_gem_path}/lib/changes.txt"

      FileUtils.touch(changes_txt)
      expect(File.exist?(changes_txt)).to be_truthy

      bundle "pristine"
      expect(File.exist?(changes_txt)).to be_falsey
    end
  end

  context "when sourced from git repo" do
    it "reverts by resetting to current revision`" do
      spec = Bundler.definition.specs["foo"].first
      changed_file = "#{spec.full_gem_path}/lib/foo.rb"
      diff = "#Pristine spec changes"

      `echo '#Pristine spec changes' >> #{changed_file}`
      expect(File.read(changed_file)).to include(diff)

      bundle "pristine"
      expect(File.read(changed_file)).to_not include(diff)
    end
  end

  context "when sourced from path" do
    it "displays warning and ignores changes sourced from local path" do
      spec = Bundler.definition.specs["bar"].first
      changes_txt = "#{spec.full_gem_path}/lib/changes.txt"
      FileUtils.touch(changes_txt)
      expect(File.exist?(changes_txt)).to be_truthy
      bundle "pristine"
      expect(out).to include("Cannot pristine #{spec.name} (#{spec.version}#{spec.git_version}). Gem is sourced from local path.")
      expect(File.exist?(changes_txt)).to be_truthy
    end
  end
end
