require "spec_helper"
require "bundler/ruby_version"

describe Bundler::RubyVersion do
  def requirement(version, patchlevel=nil, engine=nil, engine_version=nil)
    Bundler::RubyVersionRequirement.new(
      version, patchlevel, engine, engine_version)
  end

  def version(version, patchlevel=nil, engine=nil, engine_version=nil)
    Bundler::RubyVersion.new(version, patchlevel, engine, engine_version)
  end

  it "matches simple version requirements" do
    expect(requirement("2.0.0").diff(version("2.0.0"))).to be_nil
  end

  it "matches simple patchlevel requirements" do
    req = requirement("2.0.0", "645")
    ver = version("2.0.0", "645")

    expect(req.diff(ver)).to be_nil
  end

  it "matches engine" do
    req = requirement("2.0.0", "645", "ruby")
    ver = version("2.0.0", "645", "ruby")

    expect(req.diff(ver)).to be_nil
  end

  it "matches simple engine version requirements" do
    req = requirement("2.0.0", "645", "ruby", "2.0.1")
    ver = version("2.0.0", "645", "ruby", "2.0.1")

    expect(req.diff(ver)).to be_nil
  end

  it "detects engine discrepancies first" do
    req = requirement("2.0.0", "645", "ruby", "2.0.1")
    ver = requirement("2.0.1", "643", "rbx", "2.0.0")

    expect(req.diff(ver)).to eq([:engine, "ruby", "rbx"])
  end

  it "detects version discrepancies second" do
    req = requirement("2.0.0", "645", "ruby", "2.0.1")
    ver = requirement("2.0.1", "643", "ruby", "2.0.0")

    expect(req.diff(ver)).to eq([:version, "2.0.0", "2.0.1"])
  end

  it "detects engine version discrepancies third" do
    req = requirement("2.0.0", "645", "ruby", "2.0.1")
    ver = requirement("2.0.0", "643", "ruby", "2.0.0")

    expect(req.diff(ver)).to eq([:engine_version, "2.0.1", "2.0.0"])
  end

  it "detects patchlevel discrepancies last" do
    req = requirement("2.0.0", "645", "ruby", "2.0.1")
    ver = requirement("2.0.0", "643", "ruby", "2.0.1")

    expect(req.diff(ver)).to eq([:patchlevel, "645", "643"])
  end

  it "successfully matches gem requirements" do
    req = requirement(">= 2.0.0", "< 643", "ruby", "~> 2.0.1")
    ver = version("2.0.0", "642", "ruby", "2.0.5")

    expect(req.diff(ver)).to be_nil
  end

  it "successfully detects bad gem requirements" do
    req = requirement(">= 2.0.0", "< 643", "ruby", "~> 2.0.1")
    ver = version("2.0.0", "642", "ruby", "2.1.0")

    expect(req.diff(ver)).to eq([:engine_version, "~> 2.0.1", "2.1.0"])
  end
end
