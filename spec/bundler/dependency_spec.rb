require File.expand_path(File.dirname(__FILE__) + '/../spec_helper')

describe "Bundler::Dependency" do

  it "is initialized with name" do
    b = Bundler::Dependency.new("rails")
    b.name.should == "rails"
    b.version.should == ">= 0"
  end

  it "can take an optional version" do
    b = Bundler::Dependency.new("rails", :version => "3.0")
    b.version.should == "3.0"
  end

  it "can take a 'version' option" do
    b = Bundler::Dependency.new("rails", "version" => "3.0")
    b.version.should == "3.0"
  end

  it "defaults the files to require as the gem name" do
    b = Bundler::Dependency.new("rails")
    b.require_as.should == ["rails"]
  end

  it "can take a :require_as option" do
    b = Bundler::Dependency.new("actionpack", :require_as => "action_controller")
    b.require_as.should == ["action_controller"]
  end

  it "can take a 'require_as' option" do
    b = Bundler::Dependency.new("rails", "require_as" => "omg")
    b.require_as.should == ["omg"]
  end

  it "can take an array as the :require_as option" do
    b = Bundler::Dependency.new("actionpack", :require_as => ["action_controller", "action_view"])
    b.require_as.should == ["action_controller", "action_view"]
  end

  it "disallows the :rubygems environment" do
    lambda { Bundler::Dependency.new("ruby-debug", :only => "rubygems") }.
      should raise_error(Bundler::InvalidEnvironmentName)
    lambda { Bundler::Dependency.new("ruby-debug", :except => "rubygems") }.
      should raise_error(Bundler::InvalidEnvironmentName)
  end

  it "tests whether a dependency is for a specific environment (with :only)" do
    b = Bundler::Dependency.new("ruby-debug", :only => "development")
    b.should be_in("development")
    b.should be_in(:development)

    b.should_not be_in("production")
    b.should_not be_in(:production)
  end

  it "tests whether a dependency is for a specific environment (with :only => Array)" do
    b = Bundler::Dependency.new("ruby-debug", :only => ["staging", :production])
    b.should be_in("staging")
    b.should be_in(:staging)
    b.should be_in("production")
    b.should be_in(:production)

    b.should_not be_in("development")
    b.should_not be_in(:development)
  end

  it "tests whether a dependency is for a specific environment (with :except)" do
    b = Bundler::Dependency.new("ruby-debug", :except => "development")
    b.should_not be_in("development")
    b.should_not be_in(:development)

    b.should be_in("production")
    b.should be_in(:production)
  end

  it "tests whether a dependency is for a specific environment (with :except => Array)" do
    b = Bundler::Dependency.new("ruby-debug", :except => ["staging", :production])
    b.should_not be_in("staging")
    b.should_not be_in(:staging)
    b.should_not be_in("production")
    b.should_not be_in(:production)

    b.should be_in("development")
    b.should be_in(:development)
  end
end
