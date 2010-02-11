require File.expand_path('../../spec_helper', __FILE__)

describe "bundle lock with git" do
  it "doesn't break right after running lock" do
    build_git "foo"

    install_gemfile <<-G
      git "#{lib_path('foo-1.0')}"
      gem 'foo'
    G

    bundle :lock
    should_be_installed "foo 1.0.0"
  end

  it "locks a git source to the current ref" do
    build_git "foo"

    install_gemfile <<-G
      git "#{lib_path('foo-1.0')}"
      gem 'foo'
    G

    bundle :lock
    update_git "foo"
    bundle :install

    run <<-RUBY
      require 'foo'
      puts "WIN" unless defined?(FOO_PREV_REF)
    RUBY

    out.should == "WIN"
  end
end