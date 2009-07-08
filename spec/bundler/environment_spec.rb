require File.expand_path(File.dirname(__FILE__) + '/../spec_helper')

describe "Bundler::Environment" do
  before(:all) do
    FileUtils.rm_rf(tmp_dir)
    @finder = Bundler::Finder.new("file://#{gem_repo1}", "file://#{gem_repo2}")
    @bundle = @finder.resolve(build_dep('rails', '>= 0'), build_dep('json', '>= 0'))
    @bundle.download(tmp_dir)
  end

  it "is initialized with a path" do
    Bundler::Environment.new(tmp_dir)
  end

  it "raises an ArgumentError if the path does not exist" do
    lambda { Bundler::Environment.new(tmp_dir.join("omgomgbadpath")) }.should raise_error(ArgumentError)
  end

  it "raises an ArgumentError if the path does not contain a 'cache' directory" do
    lambda { Bundler::Environment.new(gem_repo1) }.should raise_error(ArgumentError)
  end

  describe "installing" do
    before(:all) do
      @environment = Bundler::Environment.new(tmp_dir)
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

    it "compiles binary gems" do
      Dir[File.join(tmp_dir, 'gems', "json-*", "**", "*.bundle")].should have_at_least(1).item
    end

    it "copies gem executables to a specified path" do
      File.exist?(File.join(tmp_dir, 'bin', 'rails')).should be_true
    end
  end
end