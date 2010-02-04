require File.expand_path('../../spec_helper', __FILE__)

describe "Bundler.require" do
  before :each do
    build_lib "one", "1.0.0" do |s|
      s.write "lib/baz.rb", "puts 'WIN'"
    end

    build_lib "two", "1.0.0" do |s|
      s.write "lib/two.rb", "puts 'WIN'"
    end

    build_lib "three", "1.0.0" do |s|
      s.write "lib/three.rb", "puts 'LOSE'"
    end

    gemfile <<-G
      path "#{lib_path('one-1.0.0')}"
      path "#{lib_path('two-1.0.0')}"
      path "#{lib_path('three-1.0.0')}"
      gem "one", :group => "bar", :require => "baz"
      gem "two", :group => "bar"
      gem "three", :group => "not"
    G
  end

  it "requires the gems" do
    run "Bundler.require('bar')"
    out.should == "WIN\nWIN"
  end

  it "requires the locked gems" do
    bundle :lock

    env = bundled_app(".bundle/environment.rb")
    out = ruby("require '#{env}'; Bundler.setup('bar'); Bundler.require('bar')")
    out.should == "WIN\nWIN"
  end
end
