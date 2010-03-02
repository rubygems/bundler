require File.expand_path('../../spec_helper', __FILE__)
describe "bundle cache with git" do
  it "base_name should strip private repo uris" do
    source  = Bundler::Source::Git.new("uri" => "git@gitthub.com:bundler.git")
    source.send(:base_name).should == "bundler"
  end
end


