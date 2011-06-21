require "spec_helper"
describe "bundle cache with git" do
  it "base_name should strip private repo uris" do
    source  = Bundler::Source::Git.new("uri" => "git@github.com:bundler.git")
    source.send(:base_name).should == "bundler"
  end
end

describe "bundle cache with network share git" do
  it "base_name should be undefined if repo uri is a network share path" do
    source = Bundler::Source::Git.new("uri" => "//MachineName/ShareFolder")
	source.send(:base_name).should == "Undetermined"
  end
 end
 