require File.expand_path(File.dirname(__FILE__) + '/../spec_helper')

describe "Bundler::Environment" do

  before :each do
    @manifest = simple_manifest
  end

  def simple_manifest(extra = nil)
    build_manifest <<-Gemfile
      clear_sources
      source "file://#{gem_repo1}"
      gem "rack"
      #{extra}
    Gemfile
  end

  def goto(where)
    if where == :app
      where = bundled_app
    else
      where = "#{bundled_app}/#{where}"
    end

    FileUtils.mkdir_p(where)
    Dir.chdir(where)
  end

  def bundle
    gem_command :bundle
  end

  def works
    run_in_context("Bundler.require_env ; puts RACK").should == "1.0.0"
  end

  it "finds the default manifest file when it's in a parent directory" do
    goto "wot"
    bundle
    works
  end

  it "sets the default bundle path to vendor/gems" do
    @manifest.gem_path.join('environment.rb').should_not exist
    goto :app
    bundle
    @manifest.gem_path.join('environment.rb').should exist
  end

  it "allows setting the bundle path in the manifest file" do
    simple_manifest %[bundle_path "#{bundled_app('gems')}"]
    goto :app
    bundle
    bundled_app('gems').should exist
  end

  it "sets the ruby-specific path relative to the bundle_path" do
    simple_manifest %[bundle_path File.join('..', 'cheezeburgerz')]
    goto 'w0t'
    bundle
    tmp_path("cheezeburgerz", Gem.ruby_engine, Gem::ConfigMap[:ruby_version], "environment.rb").should exist
  end

  it "assumes the bundle_path is relative to the manifest file no matter what the current working dir is" do
    simple_manifest %[bundle_path File.join('..', 'cheezeburgerz')]
    goto 'w0t'
    bundle
    tmp_path('cheezeburgerz').should exist
  end

  it "sets the default bindir relative to the Gemfile" do
    goto 'wot'
    bundle
    bundled_app("bin/rackup").should exist
  end

  it "allows setting the bindir in the manifest file" do
    simple_manifest %[bin_path "#{bundled_app('binz')}"]
    goto :app
    bundle
    bundled_app('binz/rackup').should exist
  end

  it "assumes the bindir is relative to the manifest file no matter what the current working dir is" do
    simple_manifest %[bin_path File.join('..', 'cheezeburgerz')]
    goto 'w0t'
    bundle
    tmp_path('cheezeburgerz/rackup').should exist
  end

  it "overwrites existing bin files" do
    bundled_app("bin/rackup").touch_p
    goto :app
    bundle
    `#{bundled_app}/bin/rackup`.should == "1.0.0\n"
  end

  it "recreates the bin files if they are missing" do
    goto :app
    bundle
    bundled_app('bin/rackup').delete
    bundle
    bundled_app('bin/rackup').should exist
  end
end
