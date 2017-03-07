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
    it "reverts by issuing `git checkout --force`" do

      spec = Bundler.definition.specs["foo"].first
      changed_file = "#{spec.full_gem_path}/lib/foo.rb"

      `echo '#Pristine spec changes' >> #{changed_file}`
      expect(File.read(changed_file)).to include('#Pristine spec changes')

      bundle "pristine"
      expect(File.read(changed_file)).to_not include('#Pristine spec changes')

    end
  end

  # context "when sourced from path" do
  #   it "ignores and warns sourced from local path" do
  #
  #     spec = Bundler.definition.specs["bar"].first
  #     expect(Bundler.ui).to receive(:warn).with("Cannot pristine #{spec.name} (#{spec.version}#{spec.git_version}) Gem is sourced from path.")
  #     bundle "pristine"
  #
  #   end
  # end

end
