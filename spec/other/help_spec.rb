require "spec_helper"

describe "bundle help" do
  # Rubygems 1.4+ no longer load gem plugins so this test is no longer needed
  rubygems_under_14 = Gem::Requirement.new("< 1.4").satisfied_by?(Gem::Version.new(Gem::VERSION))
  it "complains if older versions of bundler are installed", :if => rubygems_under_14 do
    system_gems "bundler-0.8.1"

    bundle "help", :expect_err => true
    err.should include("Please remove Bundler 0.8 versions.")
    err.should include("This can be done by running `gem cleanup bundler`.")
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
