require File.expand_path('../../spec_helper', __FILE__)

describe "gemfile lock with gems" do
  before :each do
    in_app_root
    system_gems "rack-0.9.1"
    gemfile <<-G
      source "file://#{gem_repo1}"
      gem "rack"
    G
  end

  it "locks the gemfile resolve to the versions available at the time" do
    bbl :lock

    system_gems "rack-1.0.0", "rack-0.9.1" do
      should_be_available "rack 0.9.1"
    end
  end

  it "includes the ruby version as a dependency of the lock" do
    pending
  end

  it "creates a lock.yml file in ./vendor" do
    bundled_app("vendor/lock.yml").should_not exist
    bbl :lock
    bundled_app("vendor/lock.yml").should exist
  end

  it "creates an environment.rb file in ./vendor" do
    bundled_app("vendor/environment.rb").should_not exist
    bbl :lock
    bundled_app("vendor/lock.yml").should exist
  end
end