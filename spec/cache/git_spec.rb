require "spec_helper"
describe "bundle cache with git" do
  it "base_name should strip private repo uris" do
    source  = Bundler::Source::Git.new("uri" => "git@github.com:bundler.git")
    source.send(:base_name).should == "bundler"
  end

  it "base_name should strip network share paths" do
    source = Bundler::Source::Git.new("uri" => "//MachineName/ShareFolder")
    source.send(:base_name).should == "ShareFolder"
  end
 end
