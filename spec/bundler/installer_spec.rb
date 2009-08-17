require File.expand_path(File.dirname(__FILE__) + '/../spec_helper')

describe "Installing gems" do

  describe "the bundle directory" do

    before(:each) do
      @gems = %w(
        actionmailer-2.3.2 actionpack-2.3.2 activerecord-2.3.2
        activeresource-2.3.2 activesupport-2.3.2 rails-2.3.2 rake-0.8.7)
    end

    def setup
      @gems = %w(actionmailer-2.3.2 actionpack-2.3.2 activerecord-2.3.2
                 activeresource-2.3.2 activesupport-2.3.2 rails-2.3.2
                 rake-0.8.7)
      @manifest = build_manifest <<-Gemfile
        clear_sources
        source "file://#{gem_repo1}"
        source "file://#{gem_repo2}"
        gem "rails"
      Gemfile
    end

    it "creates the bundle directory if it does not exist" do
      setup
      @manifest.install
      tmp_file("vendor", "gems").should have_cached_gems(*@gems)
    end

    it "uses the bundle directory if it is empty" do
      tmp_file("vendor", "gems").mkdir_p
      setup
      @manifest.install
      tmp_file("vendor", "gems").should have_cached_gems(*@gems)
    end

    it "uses the bundle directory if it is a valid gem repo" do
      %w(cache doc gems environments specifications).each { |dir| tmp_file("vendor", "gems", dir).mkdir_p }
      setup
      @manifest.install
      tmp_file("vendor", "gems").should have_cached_gems(*@gems)
    end

    it "does not use the bundle directory if it is not a valid gem repo" do
      tmp_file("vendor", "gems", "fail").touch_p
      lambda {
        setup
        @manifest.install
      }.should raise_error(Bundler::InvalidRepository)
    end

    it "installs the bins in the directory you specify" do
      tmp_file("omgbinz").mkdir
      m = build_manifest <<-Gemfile
        clear_sources
        source "file://#{gem_repo1}"
        source "file://#{gem_repo2}"
        bin_path "#{tmp_file("omgbinz")}"
        gem "rails"
      Gemfile
      m.install
      tmp_file("omgbinz", "rails").should exist
    end

    it "does not modify any .gemspec files that are to be installed if a directory of the same name exists" do
      dir  = tmp_file("gems", "rails-2.3.2")
      spec = tmp_file("specifications", "rails-2.3.2.gemspec")

      dir.mkdir_p
      spec.touch_p

      setup
      lambda { @manifest.install }.should_not change { [dir.mtime, spec.mtime] }
    end

    it "deletes a .gemspec file that is to be installed if a directory of the same name does not exist" do
      spec = tmp_file("vendor", "gems", "specifications", "rails-2.3.2.gemspec")
      spec.touch_p
      setup
      lambda { @manifest.install }.should change { spec.mtime }
    end

    it "deletes a directory that is to be installed if a .gemspec of the same name does not exist" do
      dir = tmp_file("vendor", "gems", "gems", "rails-2.3.2")
      dir.mkdir_p
      setup
      lambda { @manifest.install }.should change { dir.mtime }
    end

    it "keeps bin files for already installed gems" do
      setup
      @manifest.install
      lambda { @manifest.install }.should_not change { tmp_file("bin", "rails").mtime }
    end

    it "each thing in the bundle has a directory in gems" do
      setup
      @manifest.install
      @gems.each do |name|
          tmp_file("vendor", "gems", "gems", name).should be_directory
      end
    end

    it "creates a specification for each gem" do
      setup
      @manifest.install
      @gems.each do |name|
        tmp_file("vendor", "gems", "specifications", "#{name}.gemspec").should be_file
      end
    end

    it "works with prerelease gems" do
      m = build_manifest <<-Gemfile
        clear_sources
        source "file://#{gem_repo1}"
        gem "webrat", "0.4.4.racktest"
      Gemfile
      m.install
      tmp_file("vendor", "gems").should have_cached_gem("webrat-0.4.4.racktest", "nokogiri-1.3.2")
      tmp_file("vendor", "gems").should have_installed_gem("webrat-0.4.4.racktest", "nokogiri-1.3.2")
    end

    it "outputs a logger message for each gem that is installed" do
      setup
      @manifest.install
      @gems.each do |name|
        @log_output.should have_log_message("Installing #{name}.gem")
      end
    end

    it "copies gem executables to a specified path" do
      setup
      @manifest.install
      tmp_file('bin', 'rails').should be_file
    end

    it "compiles binary gems" do
      m = build_manifest <<-Gemfile
        clear_sources
        source "file://#{gem_repo2}"
        gem "json"
      Gemfile
      m.install
      Dir[tmp_file('vendor', 'gems', 'gems', 'json-*', '**', "*.#{Config::CONFIG['DLEXT']}")].should have_at_least(1).item
    end
  end
end