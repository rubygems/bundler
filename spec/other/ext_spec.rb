require 'spec_helper'

describe "Gem::Specification#match_platform" do
  it "does not match platforms other than the gem platform" do
    darwin = gem "lol", "1.0", "platform_specific-1.0-x86-darwin-10"
    darwin.match_platform(pl('java')).should be_false
  end
end

describe "Bundler::GemHelpers#generic" do
  include Bundler::GemHelpers

  it "converts non-windows platforms into ruby" do
    generic(pl('x86-darwin-10')).should == pl('ruby')
  end
end
