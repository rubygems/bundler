require File.expand_path('../../spec_helper', __FILE__)

describe "Bundler.require" do
  before :each do
    build_lib "one", "1.0.0" do |s|
      s.write "lib/baz.rb", "puts 'baz'"
      s.write "lib/qux.rb", "puts 'qux'"
    end

    build_lib "two", "1.0.0" do |s|
      s.write "lib/two.rb", "puts 'two'"
      s.add_dependency "three", "= 1.0.0"
    end

    build_lib "three", "1.0.0" do |s|
      s.write "lib/three.rb", "puts 'three'"
    end

    build_lib "four", "1.0.0" do |s|
      s.write "lib/four.rb", "puts 'four'"
    end

    gemfile <<-G
      path "#{lib_path('one-1.0.0')}"
      path "#{lib_path('two-1.0.0')}"
      path "#{lib_path('three-1.0.0')}"
      path "#{lib_path('four-1.0.0')}"
      gem "one", :group => :bar, :require => %w(baz qux)
      gem "two"
      gem "three", :group => :not
      gem "four", :require => false
    G
  end

  it "requires the gems" do
    run "Bundler.require"
    out.should == "two"

    run "Bundler.require(:bar)"
    out.should == "baz\nqux"

    run "Bundler.require(:default, :bar)"
    out.should == "two\nbaz\nqux"
  end

  it "requires the locked gems" do
    bundle :lock

    out = ruby("require 'bundler'; Bundler.setup; Bundler.require")
    out.should == "two"

    out = ruby("require 'bundler'; Bundler.setup(:bar); Bundler.require(:bar)")
    out.should == "baz\nqux"

    out = ruby("require 'bundler'; Bundler.setup(:default, :bar); Bundler.require(:default, :bar)")
    out.should == "two\nbaz\nqux"
  end
  
  describe "requiring the environment directly" do
    it "requires the locked gems" do
      bundle :lock
      env = bundled_app(".bundle/environment.rb")

      out = ruby("require '#{env}'; Bundler.setup; Bundler.require")
      out.should == "two"

      out = ruby("require '#{env}'; Bundler.setup(:bar); Bundler.require(:bar)")
      out.should == "baz\nqux"

      out = ruby("require '#{env}'; Bundler.setup(:default, :bar); Bundler.require(:default, :bar)")
      out.should == "two\nbaz\nqux"
    end
  end

  describe "using bundle exec" do
    it "requires the locked gems" do
      bundle :lock

      bundle "exec ruby -e 'Bundler.require'"
      out.should == "two"

      bundle "exec ruby -e 'Bundler.require(:bar)'"
      out.should == "baz\nqux"

      bundle "exec ruby -e 'Bundler.require(:default, :bar)'"
      out.should == "two\nbaz\nqux"
    end
  end

end
