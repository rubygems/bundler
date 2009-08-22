require File.expand_path(File.dirname(__FILE__) + '/../spec_helper')

describe "Faking gems with directories" do

  2.times do |i|
    describe "stubbing out a gem with a directory -- #{i}" do
      before(:each) do
        path = fixture_dir.join("very-simple")
        path = path.relative_path_from(tmp_file) if i == 1

        install_manifest <<-Gemfile
          clear_sources
          source "file://#{gem_repo1}"
          gem "very-simple", "1.0", :at => "#{path}"
        Gemfile
      end

      it "does not download the gem" do
        tmp_gem_path.should_not include_cached_gem("very-simple-1.0")
        tmp_gem_path.should_not include_installed_gem("very-simple-1.0")
      end

      it "has very-simple in the load path" do
        out = run_in_context "require 'very-simple' ; puts VerySimpleForTests"
        out.should == "VerySimpleForTests"
      end

      it "does not remove the directory during cleanup" do
        install_manifest <<-Gemfile
          clear_sources
          source "file://#{gem_repo1}"
        Gemfile

        fixture_dir.join("very-simple").should be_directory
      end
    end
  end

  describe "bad directory stubbing" do
    it "raises an exception unless the version is specified" do
      lambda do
        install_manifest <<-Gemfile
          clear_sources
          gem "very-simple", :at => "#{fixture_dir.join("very-simple")}"
        Gemfile
      end.should raise_error(ArgumentError, /:at/)
    end

    it "raises an exception unless the version is an exact version" do
      lambda do
        install_manifest <<-Gemfile
          clear_sources
          gem "very-simple", ">= 0.1.0", :at => "#{fixture_dir.join("very-simple")}"
        Gemfile
      end.should raise_error(ArgumentError, /:at/)
    end
  end

end