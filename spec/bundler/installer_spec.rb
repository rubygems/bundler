require File.expand_path(File.dirname(__FILE__) + '/../spec_helper')

describe "Bundler::Installer" do

  before(:all) do
    @finder = Bundler::Finder.new("file://#{gem_repo1}", "file://#{gem_repo2}")
  end

  describe "without native gems" do
    before(:all) do
      FileUtils.rm_rf(tmp_dir)
      @bundle = @finder.resolve(build_dep('rails', '>= 0'))
      @bundle.download(tmp_dir)
    end

    it "raises an ArgumentError if the path does not exist" do
      lambda { Bundler::Installer.new(tmp_dir.join("omgomgbadpath")) }.should raise_error(ArgumentError)
    end

    it "raises an ArgumentError if the path does not contain a 'cache' directory" do
      lambda { Bundler::Installer.new(gem_repo1) }.should raise_error(ArgumentError)
    end

    describe "installing gems" do

      before(:each) do
        FileUtils.rm_rf(tmp_file("gems"))
        FileUtils.rm_rf(tmp_file("specifications"))
        @environment = Bundler::Installer.new(tmp_dir)
      end

      it "installs the bins in the directory you specify" do
        FileUtils.mkdir_p tmp_file("omgbinz")
        @environment.install(:bin_dir => tmp_file("omgbinz"))
        File.exist?(tmp_file("omgbinz", "rails")).should be_true
      end

      it "does not modify any .gemspec files that are to be installed if a directory of the same name exists" do
        dir = tmp_file("gems", "rails-2.3.2")
        FileUtils.mkdir_p(dir)
        FileUtils.mkdir_p(tmp_file("specifications"))
        spec = tmp_file("specifications", "rails-2.3.2.gemspec")
        FileUtils.touch(spec)
        lambda { @environment.install }.should_not change { [File.mtime(dir), File.mtime(spec)] }
      end

      it "deletes a .gemspec file that is to be installed if a directory of the same name does not exist" do
        spec = tmp_file("specifications", "rails-2.3.2.gemspec")
        FileUtils.mkdir_p(tmp_file("specifications"))
        FileUtils.touch(spec)
        lambda { @environment.install }.should change { File.mtime(spec) }
      end

      it "deletes a directory that is to be installed if a .gemspec of the same name does not exist" do
        dir = tmp_file("gems", "rails-2.3.2")
        FileUtils.mkdir_p(dir)
        lambda { @environment.install }.should change { File.mtime(dir) }
      end

    end

    describe "after installing gems" do

      before(:all) do
        @environment = Bundler::Installer.new(tmp_dir)
        @environment.install
      end

      it "each thing in the bundle has a directory in gems" do
        @bundle.each do |spec|
          Dir[File.join(tmp_dir, 'gems', "#{spec.full_name}")].should have(1).item
        end
      end

      it "creates a specification for each gem" do
        @bundle.each do |spec|
          Dir[File.join(tmp_dir, 'specifications', "#{spec.full_name}.gemspec")].should have(1).item
        end
      end

      it "copies gem executables to a specified path" do
        File.exist?(File.join(tmp_dir, 'bin', 'rails')).should be_true
      end
    end

    it "outputs a logger message for each gem that is installed" do
      @environment = Bundler::Installer.new(tmp_dir)
      @environment.install
      @bundle.each do |spec|
        @log_output.should have_log_message("Installing #{spec.full_name}.gem")
      end
    end
  end

  describe "with native gems" do

    it "compiles binary gems" do
      FileUtils.rm_rf(tmp_dir)
      @bundle = @finder.resolve(build_dep('json', '>= 0'))
      @bundle.download(tmp_dir)
      Bundler::Installer.new(tmp_dir).install
      Dir[File.join(tmp_dir, 'gems', "json-*", "**", "*.bundle")].should have_at_least(1).item
    end

  end
end