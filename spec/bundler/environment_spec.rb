require File.expand_path(File.dirname(__FILE__) + '/../spec_helper')

# More should probably loaded in here
describe "Bundler::Environment" do
  it "can require the environment without being in context of it" do
    build_manifest <<-Gemfile
      clear_sources
      gem "rake"
    Gemfile
    Dir.chdir(bundled_app) do
      out = ruby <<-RUBY
        require 'bundler'
        Bundler::Environment.load.require_env
        puts defined?(Rake)
      RUBY
      out.should == "constant"
    end
  end

  it "only requires gems specific to the requested environment" do
    build_manifest <<-Gemfile
      clear_sources
      gem "rake", :only => "awesome"
    Gemfile
    Dir.chdir(bundled_app) do
      out = ruby <<-RUBY
        require 'bundler'
        Bundler::Environment.load.require_env
        puts defined?(Rake).inspect
      RUBY
      out.should == "nil"
      out = ruby <<-RUBY
        require 'bundler'
        Bundler::Environment.load.require_env(:awesome)
        puts defined?(Rake)
      RUBY
      out.should == "constant"
    end
  end
end