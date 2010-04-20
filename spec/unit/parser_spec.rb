require 'spec_helper'

describe "lockfile parser" do
  describe "single source, single gem" do
    before :each do
      flex_install_gemfile <<-G
        source "file://#{gem_repo1}"

        gem "rack"
      G
    end

    def locked
      lockfile = File.read(bundled_app('Gemfile.lock'))
      Bundler::Flex::LockfileParser.new(lockfile)
    end

    it "has the source in it" do
      sources = locked.sources
      sources.size.should == 1
      source = sources.first
      source.uri.should == URI("file://#{gem_repo1}/")
      source.options.keys.should == ["uri"]
    end

    it "has the rack gem in its dependencies list" do
      dependencies = locked.dependencies
      dependencies.size.should == 1
      dependency = dependencies.first
      dependency.name.should == "rack"
      dependency.requirement.should == Gem::Requirement.default
      dependency.source.should == nil
    end

    it "has rack listed as a specification" do
      specs = locked.specs
      specs.size.should == 1
    end
  end
end