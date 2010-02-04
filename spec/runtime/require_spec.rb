require File.expand_path('../../spec_helper', __FILE__)

describe "Bundler.require" do
  before :each do
    build_lib "one", "1.0.0" do |s|
      s.write "lib/baz.rb", "puts 'baz'"
      s.write "lib/qux.rb", "puts 'qux'"
    end

    build_lib "two", "1.0.0" do |s|
      s.write "lib/two.rb", "puts 'two'"
    end

    build_lib "three", "1.0.0" do |s|
      s.write "lib/three.rb", "puts 'three'"
    end

    gemfile <<-G
      path "#{lib_path('one-1.0.0')}"
      path "#{lib_path('two-1.0.0')}"
      path "#{lib_path('three-1.0.0')}"
      gem "one", :group => :bar, :require => %w(baz qux)
      gem "two"
      gem "three", :group => :not
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
    env = bundled_app(".bundle/environment.rb")

    out = ruby("require '#{env}'; Bundler.setup; Bundler.require")
    out.should == "two"

    out = ruby("require '#{env}'; Bundler.setup(:bar); Bundler.require(:bar)")
    out.should == "baz\nqux"

    out = ruby("require '#{env}'; Bundler.setup(:default, :bar); Bundler.require(:default, :bar)")
    out.should == "two\nbaz\nqux"
  end
end
