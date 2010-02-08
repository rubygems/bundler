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

    build_lib "five", "1.0.0", :no_default => true do |s|
      s.write "lib/mofive.rb", "puts 'five'"
    end

    build_lib "six", "1.0.0" do |s|
      s.write "lib/six.rb", "puts 'six'"
    end

    gemfile <<-G
      path "#{lib_path}"
      gem "one", :group => :bar, :require => %w(baz qux)
      gem "two"
      gem "three", :group => :not
      gem "four", :require => false
      gem "five"
      gem "six", :group => "string"
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

  it "requires the gems with strings as group names" do
    run 'Bundler.require("bar")'
    out.should == "baz\nqux"

    run 'Bundler.require(:string)'
    out.should == "six"
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

  it "allows requiring gems with non standard names explicitly" do
    run "Bundler.require ; require 'mofive'"
    out.should == "two\nfive"
  end

  it "raises an exception if a require is specified but the file does not exist" do
    gemfile <<-G
      path "#{lib_path}"
      gem "two", :require => 'fail'
    G

    run <<-R
      begin
        Bundler.require
      rescue LoadError => e
        puts e.message
      end
    R
    out.should == 'no such file to load -- fail'
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
