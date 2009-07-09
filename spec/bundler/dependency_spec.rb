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
  
  it "can take an :environments option" do
    b = Bundler::Dependency.new("ruby-debug", :environments => "development")
    b.environments.should == ["development"]
  end
  
  it "can take an 'environments' option" do
    b = Bundler::Dependency.new("ruby-debug", "environments" => "development")
    b.environments.should == ["development"]
  end
  
  it "can take an array as the :environments option" do
    b = Bundler::Dependency.new("ruby-debug", :environments => ["development", "test"])
    b.environments.should == ["development", "test"]
  end
  
  it "defaults the :environments option to []" do
    b = Bundler::Dependency.new("rails")
    b.environments.should == []
  end
end