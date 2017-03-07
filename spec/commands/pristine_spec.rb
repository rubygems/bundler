# frozen_string_literal: true
require "spec_helper"
require "fileutils"

RSpec.describe "bundle pristine" do
  before :each do
    build_repo2 do
      build_gem "weakling"
      build_git "foo", :path => lib_path("foo")
      build_lib "bar", :path => lib_path("foo")
    end

    install_gemfile <<-G
      source "file://#{gem_repo2}"
      gem "weakling"
      gem "foo", :git => "#{lib_path("foo")}"
      gem "bar", :path => "#{lib_path("foo")}"
    G

    bundle "install"
  end

  it "reverts gem sourced from Rubygems to its cached .gem file" do

    spec = Bundler.definition.specs["weakling"].first
    changes_txt = "#{spec.full_gem_path}/lib/changes.txt"
    expect(File.exist?(changes_txt)).to be_falsey
    expect(File.exist?(spec.cache_file)).to be_truthy

    FileUtils.touch(changes_txt)

    expect(File.exist?(changes_txt)).to be_truthy

    bundle "pristine"

    expect(File.exist?(changes_txt)).to be_falsey
  end

  it "reverts gem sourced from Git by issuing `git checkout --force`" do

    spec = Bundler.definition.specs["foo"].first

  end

  it "ignores gem sourced from local path" do
    
    spec = Bundler.definition.specs["bar"].first

  end
end
