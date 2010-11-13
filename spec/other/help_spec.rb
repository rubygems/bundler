require "spec_helper"

describe "bundle help" do
  it "complains if older versions of bundler are installed" do
    system_gems "bundler-0.8.1"

    bundle "help", :expect_err => true
    err.should == "Please remove older versions of bundler. This can be done by running `gem cleanup bundler`."
  end

  it "uses groff when available" do
    fake_groff!

    bundle "help gemfile"
    out.should == %|["-Wall", "-mtty-char", "-mandoc", "-Tascii", "#{root}/lib/bundler/man/gemfile.5"]|
  end

  it "prefixes bundle commands with bundle- when finding the groff files" do
    fake_groff!

    bundle "help install"
    out.should == %|["-Wall", "-mtty-char", "-mandoc", "-Tascii", "#{root}/lib/bundler/man/bundle-install"]|
  end

  it "simply outputs the txt file when there is no groff on the path" do
    kill_path!

    bundle "help install", :expect_err => true
    out.should =~ /BUNDLE-INSTALL/
  end

  it "still outputs the old help for commands that do not have man pages yet" do
    bundle "help check"
    out.should include("Check searches the local machine")
  end
end
