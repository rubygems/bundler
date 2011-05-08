require "spec_helper"

describe "bundle benchmark" do
  before :each do
    install_gemfile <<-G
      source "file://#{gem_repo1}"
      gem "rails"
    G
  end

  it "prints out the require times for each gem" do
    bundle :benchmark
    
    out.should =~ / \* rails \(\d+ ms\)/
  end
end
