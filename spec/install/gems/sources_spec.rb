require "spec_helper"

describe "bundle install with gems on multiple sources" do
  # repo1 is built automatically before all of the specs run
  # it contains rack-obama 1.0.0 and rack 0.9.1 & 1.0.0 amongst other gems

  it "searches gem sources from last to first" do
    # Oh no! Someone evil is trying to hijack rack :(
    # need this to be broken to check for correct source ordering
    build_repo gem_repo3 do
      build_gem "rack", "1.0.0" do |s|
        s.write "lib/rack.rb", "RACK = 'FAIL'"
      end
    end

    gemfile <<-G
      source "file://#{gem_repo3}"
      source "file://#{gem_repo1}"
      gem "rack-obama"
      gem "rack"
    G

    bundle :install

    should_be_installed("rack-obama 1.0.0", "rack 1.0.0")
  end
end
