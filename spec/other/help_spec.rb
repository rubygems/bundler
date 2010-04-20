require "spec_helper"

describe "bundle help" do
  it "complains if older versions of bundler are installed" do
    system_gems "bundler-0.8.1"

    bundle "help", :expect_err => true
    err.should == "Please remove older versions of bundler. This can be done by running `gem cleanup bundler`."
  end
end