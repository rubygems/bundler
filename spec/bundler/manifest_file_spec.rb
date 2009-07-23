require File.expand_path(File.dirname(__FILE__) + '/../spec_helper')

describe "Bundler::Manifest" do
  before(:each) do
    @original_pwd = Dir.pwd
    FileUtils.rm_rf(tmp_dir)
    FileUtils.mkdir_p(tmp_dir)
  end

  after(:each) do
    Dir.chdir(@original_pwd)
  end

  it "finds the default manifest file" do
    Dir.chdir(tmp_dir)
    FileUtils.touch(tmp_file("Gemfile"))
    Bundler::ManifestFile.load.filename.should == tmp_file("Gemfile")
  end

  it "finds the default manifest file when it's in a parent directory" do
    FileUtils.mkdir_p(tmp_file("wot"))
    FileUtils.touch(tmp_file("Gemfile"))
    Dir.chdir(tmp_file("wot"))
    Bundler::ManifestFile.load.filename.should == tmp_file("Gemfile")
  end

  it "sets the default bundle path to vendor/gems" do
    Dir.chdir(tmp_dir)
    FileUtils.touch(tmp_file("Gemfile"))
    Bundler::ManifestFile.load.gem_path.should == tmp_file("vendor", "gems")
  end

  it "sets the default bundle path relative to the Gemfile" do
    FileUtils.mkdir_p(tmp_file("wot"))
    FileUtils.touch(tmp_file("Gemfile"))
    Dir.chdir(tmp_file("wot"))
    Bundler::ManifestFile.load.gem_path.should == tmp_file("vendor", "gems")
  end

  it "sets the default bindir relative to the Gemfile" do
    FileUtils.mkdir_p(tmp_file("wot"))
    FileUtils.touch(tmp_file("Gemfile"))
    Dir.chdir(tmp_file("wot"))
    Bundler::ManifestFile.load.bindir.should == tmp_file("bin")
  end
end
