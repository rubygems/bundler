require File.expand_path('../../spec_helper', __FILE__)

describe "bbl lock with gems" do
  before :each do
    in_app_root
  end

  it "locks the gemfile resolve to the versions available at the time" do
    gemfile <<-G
      source "file://#{gem_repo1}"
      gem "rack"
    G

    system_gems "rack-0.9.1" do
      bbl :lock
    end

    system_gems "rack-1.0.0", "rack-0.9.1" do
      should_be_available "rack 0.9.1"
    end
  end

  it "includes the ruby version as a dependency of the lock" do
    pending
  end
end