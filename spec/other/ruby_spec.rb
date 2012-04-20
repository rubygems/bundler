require "spec_helper"

describe "bundle ruby" do
  it "returns ruby version when explicit" do
    gemfile <<-G
      source "file://#{gem_repo1}"
      ruby_version "1.9.3", :engine => 'ruby', :engine_version => '1.9.3'

      gem "foo"
    G

    bundle "ruby"
    
    out.should eq("ruby 1.9.3 (ruby 1.9.3)")
  end

  it "engine defaults to MRI" do
    gemfile <<-G
      source "file://#{gem_repo1}"
      ruby_version "1.9.3"

      gem "foo"
    G

    bundle "ruby"

    out.should eq("ruby 1.9.3 (ruby 1.9.3)")
  end

  it "handles jruby" do
    gemfile <<-G
      source "file://#{gem_repo1}"
      ruby_version "1.8.7", :engine => 'jruby', :engine_version => '1.6.5'

      gem "foo"
    G

    bundle "ruby"

    out.should eq("ruby 1.8.7 (jruby 1.6.5)")
  end

  it "handles rbx" do
    gemfile <<-G
      source "file://#{gem_repo1}"
      ruby_version "1.8.7", :engine => 'rbx', :engine_version => '1.2.4'

      gem "foo"
    G

    bundle "ruby"

    out.should eq("ruby 1.8.7 (rbx 1.2.4)")
  end

  it "raises an error if engine is used but engine version is not" do
    gemfile <<-G
      source "file://#{gem_repo1}"
      ruby_version "1.8.7", :engine => 'rbx'

      gem "foo"
    G

    bundle "ruby", :exitstatus => true

    exitstatus.should_not == 0
  end

  it "raises an error if engine_version is used but engine is not" do
    gemfile <<-G
      source "file://#{gem_repo1}"
      ruby_version "1.8.7", :engine_version => '1.2.4'

      gem "foo"
    G

    bundle "ruby", :exitstatus => true

    exitstatus.should_not == 0
  end

  it "raises an error if engine version doesn't match ruby version for mri" do
    gemfile <<-G
      source "file://#{gem_repo1}"
      ruby_version "1.8.7", :engine => 'ruby', :engine_version => '1.2.4'

      gem "foo"
    G

    bundle "ruby", :exitstatus => true

    exitstatus.should_not == 0
  end
end
