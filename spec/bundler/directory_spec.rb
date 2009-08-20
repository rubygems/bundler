require File.expand_path(File.dirname(__FILE__) + '/../spec_helper')

describe "Faking gems with directories" do

  describe "stubbing out a gem with a directory" do
    before(:each) do
      pending
      install_manifest <<-Gemfile
        clear_sources
        source "file://#{gem_repo1}"
        gem "very-simple", "1.0", :at => "#{fixture_dir.join("very-simple")}"
      Gemfile
    end

    it "does not download the gem" do
      tmp_gem_path.should_not include_cached_gem("very-simple-1.0")
      tmp_gem_path.should_not include_installed_gem("very-simple-1.0")
    end

    it "sets the lib directory in the load path" do
      "runtime".should have_load_path(fixture_dir, "very-simple" => "lib")
    end
  end

  describe "bad directory stubbing" do
    it "raises an exception unless the version is specified" do
      lambda do
        install_manifest <<-Gemfile
          clear_sources
          gem "very-simple", :at => "#{fixture_dir.join("very-simple")}"
        Gemfile
      end.should raise_error
    end

    it "raises an exception unless the version is an exact version" do
      lambda do
        install_manifest <<-Gemfile
          clear_sources
          gem "very-simple", ">= 0.1.0", :at => "#{fixture_dir.join("very-simple")}"
        Gemfile
      end.should raise_error
    end
  end

end