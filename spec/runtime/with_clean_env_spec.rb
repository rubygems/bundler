require "spec_helper"

describe "Bundler.with_clean_env" do

  it "should reset and restore the environment" do
    gem_path = ENV['GEM_PATH']

    Bundler.with_clean_env do
      `echo $GEM_PATH`.strip.should_not == gem_path
    end

    ENV['GEM_PATH'].should == gem_path
  end

end