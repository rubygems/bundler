require "spec_helper"

describe "bundle lock with gems" do
  before :each do
    system_gems "rack-0.9.1"
    gemfile <<-G
      source "file://#{gem_repo1}"
      gem "rack"
    G
  end

  it "locks the gemfile resolve to the versions available at the time" do
    bundle :lock

    system_gems "rack-1.0.0", "rack-0.9.1" do
      should_be_available "rack 0.9.1"
    end
  end

  it "includes the ruby version as a dependency of the lock" do
    pending
  end

  it "creates a lock.yml file in ./vendor" do
    bundled_app("Gemfile.lock").should_not exist
    bundle :lock
    bundled_app("Gemfile.lock").should exist
  end

  it "creates an environment.rb file in ./vendor" do
    bundled_app(".bundle/environment.rb").should_not exist
    bundle :lock
    bundled_app(".bundle/environment.rb").should exist
  end

  it "relocks if bundle locking twice" do
    bundle :lock

    should_be_available "rack 0.9.1"

    system_gems "rack-1.0.0", "rack-0.9.1" do
      gemfile <<-G
        source "file://#{gem_repo1}"
        gem "rack", "1.0.0"
      G

      bundle :lock
      should_be_available "rack 1.0.0"
    end
  end
end
