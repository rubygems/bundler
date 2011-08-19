require "spec_helper"

describe "bundle grep" do
  it "prints grep output" do
    install_gemfile <<-G
      source "file://#{gem_repo1}"
      gem "rake"
    G

    bundle "grep 'RAKE -- Ruby Make'"
    out.should =~ /rake-0.8.7\/README:RAKE -- Ruby Make/i
  end

end
