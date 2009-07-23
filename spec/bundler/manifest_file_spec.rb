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

  def manifest(*args)
    path = args.unshift if args.first.is_a?(Pathname)
    str  = args.unshift || ""
    File.open(path || tmp_file("Gemfile"), 'w') do |f|
      f.puts str
    end
  end

  it "finds the default manifest file" do
    manifest
    Dir.chdir(tmp_dir)
    Bundler::ManifestFile.load.filename.should == tmp_file("Gemfile")
  end

  it "finds the default manifest file when it's in a parent directory" do
    manifest
    FileUtils.mkdir_p(tmp_file("wot"))
    Dir.chdir(tmp_file("wot"))
    Bundler::ManifestFile.load.filename.should == tmp_file("Gemfile")
  end

  it "sets the default bundle path to vendor/gems" do
    manifest
    Dir.chdir(tmp_dir)
    Bundler::ManifestFile.load.gem_path.should == tmp_file("vendor", "gems")
  end

  it "allows setting the bundle path in the manifest file" do
    manifest <<-Gemfile
      bundle_path "#{tmp_file('gems')}"
    Gemfile
    Dir.chdir(tmp_dir)
    Bundler::ManifestFile.load.gem_path.should == tmp_file("gems")
  end

  it "assumes the bundle_path is relative to the manifest file no matter what the current working dir is" do
    manifest <<-Gemfile
      bundle_path File.join('..', 'cheezeburgerz')
    Gemfile
    FileUtils.mkdir_p(tmp_file('w0t'))
    Dir.chdir(tmp_file('w0t'))
    Bundler::ManifestFile.load.gem_path.should == tmp_file('..', 'cheezeburgerz')
  end

  it "sets the default bundle path relative to the Gemfile" do
    manifest
    FileUtils.mkdir_p(tmp_file("wot"))
    Dir.chdir(tmp_file("wot"))
    Bundler::ManifestFile.load.gem_path.should == tmp_file("vendor", "gems")
  end

  it "sets the default bindir relative to the Gemfile" do
    manifest
    FileUtils.mkdir_p(tmp_file("wot"))
    Dir.chdir(tmp_file("wot"))
    Bundler::ManifestFile.load.bindir.should == tmp_file("bin")
  end

  it "allows setting the bindir in the manifest file" do
    manifest <<-Gemfile
      bin_path "#{tmp_file('binz')}"
    Gemfile
    Dir.chdir(tmp_dir)
    Bundler::ManifestFile.load.bindir.should == tmp_file('binz')
  end

  it "assumes the bindir is relative to the manifest file no matter what the current working dir is" do
    manifest <<-Gemfile
      bin_path File.join('..', 'cheezeburgerz')
    Gemfile
    FileUtils.mkdir_p(tmp_file('w0t'))
    Dir.chdir(tmp_file('w0t'))
    Bundler::ManifestFile.load.bindir.should == tmp_file('..', 'cheezeburgerz')
  end
end
