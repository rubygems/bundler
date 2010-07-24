require 'spec_helper'

describe "Gem::Specification#match_platform" do
  it "works" do
    darwin = gem "lol", "1.0", "platform_specific-1.0-x86-darwin-10"
    darwin.match_platform(pl('java')).should be_false
  end
end

describe "Bundler::GemHelpers#generic" do
  include Bundler::GemHelpers

  it "works" do
    generic(pl('x86-darwin-10')).should == pl('ruby')
  end
end
