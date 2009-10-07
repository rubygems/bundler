require File.expand_path(File.dirname(__FILE__) + '/../spec_helper')

describe "Bundler::Environment" do

  it "finds the default manifest file" do
    build_manifest_file
    Dir.chdir(bundled_app)
    Bundler::Environment.load.filename.should == bundled_app("Gemfile")
  end

  it "finds the default manifest file when it's in a parent directory" do
    build_manifest_file
    FileUtils.mkdir_p(bundled_app("wot"))
    Dir.chdir(bundled_app("wot"))
    Bundler::Environment.load.filename.should == bundled_app("Gemfile")
  end

  it "sets the default bundle path to vendor/gems" do
    build_manifest_file
    Dir.chdir(bundled_app)
    Bundler::Environment.load.gem_path.should == bundled_app("vendor", "gems")
  end

  it "allows setting the bundle path in the manifest file" do
    build_manifest_file <<-Gemfile
      bundle_path "#{bundled_app('gems')}"
    Gemfile
    Dir.chdir(bundled_app)
    Bundler::Environment.load.gem_path.should == bundled_app("gems")
  end

  it "assumes the bundle_path is relative to the manifest file no matter what the current working dir is" do
    build_manifest_file <<-Gemfile
      bundle_path File.join('..', 'cheezeburgerz')
    Gemfile
    FileUtils.mkdir_p(bundled_app('w0t'))
    Dir.chdir(bundled_app('w0t'))
    Bundler::Environment.load.gem_path.should == tmp_path('cheezeburgerz')
  end

  it "sets the default bundle path relative to the Gemfile" do
    build_manifest_file
    FileUtils.mkdir_p(bundled_app("wot"))
    Dir.chdir(bundled_app("wot"))
    Bundler::Environment.load.gem_path.should == bundled_app("vendor", "gems")
  end

  it "sets the default bindir relative to the Gemfile" do
    build_manifest_file
    FileUtils.mkdir_p(bundled_app("wot"))
    Dir.chdir(bundled_app("wot"))
    Bundler::Environment.load.bindir.should == bundled_app("bin")
  end

  it "allows setting the bindir in the manifest file" do
    build_manifest_file <<-Gemfile
      bin_path "#{bundled_app('binz')}"
    Gemfile
    Dir.chdir(bundled_app)
    Bundler::Environment.load.bindir.should == bundled_app('binz')
  end

  it "assumes the bindir is relative to the manifest file no matter what the current working dir is" do
    build_manifest_file <<-Gemfile
      bin_path File.join('..', 'cheezeburgerz')
    Gemfile
    FileUtils.mkdir_p(bundled_app('w0t'))
    Dir.chdir(bundled_app('w0t'))
    Bundler::Environment.load.bindir.should == tmp_path('cheezeburgerz')
  end

  it "overwrites existing bin files" do
    bundled_app('bin').mkdir_p
    File.open("#{bundled_app}/bin/rackup", 'w') do |f|
      f.print "omg"
    end

    install_manifest <<-Gemfile
      clear_sources
      source "file://#{gem_repo1}"
      gem "rack"
    Gemfile

    File.read("#{bundled_app}/bin/rackup").should_not == "omg"
  end

  it "recreates the bin files if they are missing" do
    install_manifest <<-Gemfile
      clear_sources
      source "file://#{gem_repo1}"
      gem "rack"
    Gemfile

    bundled_app('bin/rackup').delete
    Dir.chdir(bundled_app) { gem_command :bundle }
    bundled_app('bin/rackup').should exist
  end

  it "ensures the source sources contains no duplicate" do
    build_manifest_file <<-Gemfile
      source "http://gems.rubyforge.org"
      source "http://gems.github.org"
      source "http://gems.github.org"
    Gemfile
    FileUtils.mkdir_p(bundled_app("baz"))
    Dir.chdir(bundled_app("baz"))
    Bundler::Environment.load.sources.should have(3).items
  end

  it "inserts new sources at the end if the default has been removed" do
    m = build_manifest <<-Gemfile
      clear_sources
      source "http://gems.rubyforge.org"
      source "http://gems.github.com"
    Gemfile
    m.sources.map{|s| s.uri.to_s}.should ==
      %w(http://gems.rubyforge.org http://gems.github.com)
  end
end
