require File.expand_path(File.dirname(__FILE__) + '/../spec_helper')

describe "Bundling DSL" do

  before(:all) do
    FileUtils.rm_rf(tmp_dir)
    FileUtils.mkdir_p(tmp_dir)
  end

  def build_manifest(str = "")
    File.open(tmp_file("Gemfile"), "w") do |f|
      f.puts str
    end
    Bundler::ManifestFile.load(tmp_file("Gemfile"))
  end

  it "allows specifying the path to bundle gems to" do
    build_manifest.gem_path.should == tmp_file("vendor", "gems")
  end

  it "allows specifying sources" do
    manifest = build_manifest <<-DSL
      source "http://gems.github.com"
    DSL

    manifest.sources.first.should == URI.parse("http://gems.rubyforge.org")
    manifest.sources.last.should  == URI.parse("http://gems.github.com")
  end

  it "allows specifying gems" do
    manifest = build_manifest <<-DSL
      gem "rails"
    DSL

    manifest.dependencies.first.name.should == "rails"
  end

  it "allows specifying gem versions" do
    manifest = build_manifest <<-DSL
      gem "rails", ">= 2.0.0"
    DSL

    manifest.dependencies.first.version.should == ">= 2.0.0"
  end

  it "allows specifying how to require the gem" do
    manifest = build_manifest <<-DSL
      gem "actionpack", :require_as => "action_controller"
    DSL

    manifest.dependencies.first.require_as.should == ["action_controller"]
  end

  it "allows specifying 'only' restrictions on the environment" do
    manifest = build_manifest <<-DSL
      gem "ruby-debug", :only => "development"
    DSL

    manifest.dependencies.first.only.should == ["development"]
  end

  it "allows specifying 'except' restrictions on the environment" do
    manifest = build_manifest <<-DSL
      gem "newrelic_rpm", :except => "staging"
    DSL

    manifest.dependencies.first.except.should == ["staging"]
  end

  it "loads the manifest from a file" do
    File.open(tmp_file("manifest.rb"), 'w') do |file|
      file.puts <<-DSL
        gem "rails"
      DSL
    end

    manifest = Bundler::ManifestFile.load(tmp_file("manifest.rb"))
    manifest.dependencies.first.name.should == "rails"
  end

  it "allows specifying an arbitrary number of sources and gems" do
    manifest = build_manifest <<-DSL
      gem "thor"
      source "http://gems.github.com"
      gem "wycats-merb-core"
      gem "mislav-will_paginate"
      source "http://gems.example.org"
      gem "uuidtools"
    DSL

    manifest.sources.should == [
      URI.parse("http://gems.rubyforge.org"),
      URI.parse("http://gems.github.com"),
      URI.parse("http://gems.example.org")
    ]

    manifest.dependencies.map { |d| d.name }.should == %w(
      thor
      wycats-merb-core
      mislav-will_paginate
      uuidtools
    )
  end

  it "can bundle gems in a manifest defined through the DSL" do
    manifest = build_manifest <<-DSL
      sources.clear

      source "file://#{gem_repo1}"
      source "file://#{gem_repo2}"
      gem "merb-core", "= 1.0.12"
      gem "activerecord", "> 2.2"
    DSL

    gems = %w(
      abstract-1.0.0 activerecord-2.3.2 activesupport-2.3.2 erubis-2.6.4
      extlib-0.9.12 json_pure-1.1.7 merb-core-1.0.12 mime-types-1.16
      rack-1.0.0 rake-0.8.7 rspec-1.2.8 thor-0.9.9)

    manifest.install

    tmp_gem_path.should have_cached_gems(*gems)
    tmp_gem_path.should have_installed_gems(*gems)

    load_paths = {}
    gems.each { |g| load_paths[g] = %w(bin lib) }

    tmp_gem_path('environments', 'default.rb').should have_load_paths(tmp_gem_path, load_paths)
  end

  it "outputs a pretty error when an environment is named rubygems" do
    lambda do
      build_manifest <<-DSL
        sources.clear

        gem "extlib", :only => "rubygems"
      DSL
    end.should raise_error(Bundler::InvalidEnvironmentName)
  end
end
