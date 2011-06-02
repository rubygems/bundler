require "spec_helper"
describe "bundle cache with hg" do
  it "base_name should strip private repo uris" do
    source  = Bundler::Source::Mercurial.new("uri" => "ssh://hg@bitbucket.org/nolith/eusplazio")
    source.send(:base_name).should == "eusplazio"
  end
end


