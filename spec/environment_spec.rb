require File.expand_path(File.dirname(__FILE__) + '/spec_helper')

describe "Bundler::Environment" do
  before(:all) do
    @finder = Bundler::Finder.new("file://#{fixtures1}", "file://#{fixtures2}")
    @bundle = @finder.resolve(build_dep('rails', '>= 0'))
    @bundle.download(tmp_dir)
  end

  it "is initialized with a path" do
    Bundler::Environment.new(tmp_dir)
  end

  it "raises an ArgumentError if the path does not exist" do
    lambda { Bundler::Environment.new(tmp_dir.join("omgomgbadpath")) }.should raise_error(ArgumentError)
  end

  it "raises an ArgumentError if the path does not contain a 'cache' directory" do
    lambda { Bundler::Environment.new(fixtures1) }.should raise_error(ArgumentError)
  end
end