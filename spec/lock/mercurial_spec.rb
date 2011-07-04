require "spec_helper"

describe "bundle lock with hg gems" do
  before :each do
    build_hg "foo"

    install_gemfile <<-G
      gem 'foo', :hg => "#{lib_path('foo-1.0')}"
    G
  end

  it "doesn't break right after running lock" do
    should_be_installed "foo 1.0.0"
  end

  it "locks a hg source to the current ref" do
    update_hg "foo"
    bundle :install

    run <<-RUBY
      require 'foo'
      puts "WIN" unless defined?(FOO_PREV_REF)
    RUBY

    out.should == "WIN"
  end

  it "provides correct #full_gem_path" do
    run <<-RUBY
      puts Bundler.rubygems.find_name('foo').first.full_gem_path
    RUBY
    out.should == bundle("show foo")
  end

end
