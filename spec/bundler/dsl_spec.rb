require File.expand_path(File.dirname(__FILE__) + '/../spec_helper')

describe "Bundling DSL" do

  def build_manifest(str = "")
    Bundler::ManifestBuilder.build(tmp_dir, str)
  end

  it "allows specifying the path to bundle gems to" do
    build_manifest.path.should == tmp_dir
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
end