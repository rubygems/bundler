require "spec_helper"

describe "Bundler.setup with multi platform stuff" do
  it "raises a friendly error when gems are missing locally" do
    gemfile <<-G
      source "file://#{gem_repo1}"
      gem "rack"
    G

    lockfile <<-G
      GEM
        remote: file:#{gem_repo1}/
        specs:
          rack (1.0)

      PLATFORMS
        #{local_tag}

      DEPENDENCIES
        rack
    G

    ruby <<-R
      begin
        require 'bundler'
        Bundler.setup
      rescue Bundler::GemNotFound => e
        puts "WIN"
      end
    R

    out.should == "WIN"
  end
end