require File.expand_path(File.dirname(__FILE__) + '/../spec_helper')

describe "Bundler::Manifest" do

  it "finds the default manifest file" do
    build_manifest_file
    Dir.chdir(tmp_dir)
    Bundler::Manifest.load.filename.should == tmp_file("Gemfile")
  end

  it "finds the default manifest file when it's in a parent directory" do
    build_manifest_file
    FileUtils.mkdir_p(tmp_file("wot"))
    Dir.chdir(tmp_file("wot"))
    Bundler::Manifest.load.filename.should == tmp_file("Gemfile")
  end

  it "sets the default bundle path to vendor/gems" do
    build_manifest_file
    Dir.chdir(tmp_dir)
    Bundler::Manifest.load.gem_path.should == tmp_file("vendor", "gems")
  end

  it "allows setting the bundle path in the manifest file" do
    build_manifest_file <<-Gemfile
      bundle_path "#{tmp_file('gems')}"
    Gemfile
    Dir.chdir(tmp_dir)
    Bundler::Manifest.load.gem_path.should == tmp_file("gems")
  end

  it "assumes the bundle_path is relative to the manifest file no matter what the current working dir is" do
    build_manifest_file <<-Gemfile
      bundle_path File.join('..', 'cheezeburgerz')
    Gemfile
    FileUtils.mkdir_p(tmp_file('w0t'))
    Dir.chdir(tmp_file('w0t'))
    Bundler::Manifest.load.gem_path.should == tmp_file('..', 'cheezeburgerz')
  end

  it "sets the default bundle path relative to the Gemfile" do
    build_manifest_file
    FileUtils.mkdir_p(tmp_file("wot"))
    Dir.chdir(tmp_file("wot"))
    Bundler::Manifest.load.gem_path.should == tmp_file("vendor", "gems")
  end

  it "sets the default bindir relative to the Gemfile" do
    build_manifest_file
    FileUtils.mkdir_p(tmp_file("wot"))
    Dir.chdir(tmp_file("wot"))
    Bundler::Manifest.load.bindir.should == tmp_file("bin")
  end

  it "allows setting the bindir in the manifest file" do
    build_manifest_file <<-Gemfile
      bin_path "#{tmp_file('binz')}"
    Gemfile
    Dir.chdir(tmp_dir)
    Bundler::Manifest.load.bindir.should == tmp_file('binz')
  end

  it "assumes the bindir is relative to the manifest file no matter what the current working dir is" do
    build_manifest_file <<-Gemfile
      bin_path File.join('..', 'cheezeburgerz')
    Gemfile
    FileUtils.mkdir_p(tmp_file('w0t'))
    Dir.chdir(tmp_file('w0t'))
    Bundler::Manifest.load.bindir.should == tmp_file('..', 'cheezeburgerz')
  end

  it "ensures the source sources contains no duplicate" do
    build_manifest_file <<-Gemfile
      source "http://gems.rubyforge.org"
      source "http://gems.github.org"
      source "http://gems.github.org"
    Gemfile
    FileUtils.mkdir_p(tmp_file("baz"))
    Dir.chdir(tmp_file("baz"))
    Bundler::Manifest.load.sources.should have(2).items
  end

  it "inserts new sources before rubyforge" do
    m = build_manifest <<-Gemfile
      source "http://gems.github.com"
    Gemfile
    m.sources.map{|s| s.uri.to_s}.should ==
      %w(http://gems.github.com http://gems.rubyforge.org)
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
