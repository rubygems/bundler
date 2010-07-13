require "spec_helper"

describe "Running bin/* commands" do
  before :each do
    gemfile <<-G
      source "file://#{gem_repo1}"
      gem "rack"
    G
  end

  it "runs the bundled command when in the bundle" do
    bundle "install --binstubs"

    build_gem "rack", "2.0", :to_system => true do |s|
      s.executables = "rackup"
    end

    gembin "rackup"
    out.should == "1.0.0"
  end

  it "allows the location of the gem stubs to be specified" do
    bundle "install --binstubs gbin"

    bundled_app("bin").should_not exist
    bundled_app("gbin/rackup").should exist

    gembin bundled_app("gbin/rackup")
    out.should == "1.0.0"
  end

  it "allows absolute paths as a specification of where to install bin stubs" do
    bundle "install --binstubs #{tmp}/bin"

    gembin tmp("bin/rackup")
    out.should == "1.0.0"
  end

  it "runs the bundled command when out of the bundle" do
    bundle "install --binstubs"

    build_gem "rack", "2.0", :to_system => true do |s|
      s.executables = "rackup"
    end

    Dir.chdir(tmp) do
      gembin "rackup"
      out.should == "1.0.0"
    end
  end

  it "works with gems in path" do
    build_lib "rack", :path => lib_path("rack") do |s|
      s.executables = 'rackup'
    end

    gemfile <<-G
      gem "rack", :path => "#{lib_path('rack')}"
    G

    bundle "install --binstubs"

    build_gem 'rack', '2.0', :to_system => true do |s|
      s.executables = 'rackup'
    end

    gembin "rackup"
    out.should == '1.0'
  end

  it "don't bundle da bundla" do
    build_gem "bundler", Bundler::VERSION, :to_system => true do |s|
      s.executables = "bundle"
    end

    gemfile <<-G
      source "file://#{gem_repo1}"
      gem "bundler"
    G

    bundle "install --binstubs"

    bundled_app("bin/bundle").should_not exist
  end

  it "does not generate bin stubs if the option was not specified" do
    bundle "install"

    bundled_app("bin/rackup").should_not exist
  end

  it "remembers that the option was specified" do
    gemfile <<-G
      source "file://#{gem_repo1}"
      gem "activesupport"
    G

    bundle "install --binstubs"

    gemfile <<-G
      source "file://#{gem_repo1}"
      gem "activesupport"
      gem "rack"
    G

    bundle "install"

    bundled_app("bin/rackup").should exist
  end
end