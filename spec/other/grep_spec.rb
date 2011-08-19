require "spec_helper"

describe "bundle grep" do
#   before :each do
# #    system_gems "rack-1.0.0"
#   end

  it "prints grep output" do
    # install_gemfile <<-G
    #   source "file://#{gem_repo1}"
    #   gem "rails"
    # G
    # install_gemfile <<-G
    #   gem "rack"
    # G
    install_gemfile <<-G
      source "file://#{gem_repo1}"
      gem "rake"
    G

    bundle "grep 'RAKE -- Ruby Make'"
    out.should =~ /rake-0.8.7\/README:RAKE -- Ruby Make/i
  end

end
