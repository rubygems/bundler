require File.expand_path('../../spec_helper', __FILE__)

describe "gemfile lock with git" do
  it "locks a git source to the current ref" do
    in_app_root

    build_git "foo"

    install_gemfile <<-G
      git "#{lib_path('foo-1.0')}"
      gem 'foo'
    G

    bbl :lock
    update_git "foo"
    bbl :install

    run <<-RUBY
      require 'foo'
      puts "WIN" unless defined?(FOO_PREV_REF)
    RUBY

    out.should == "WIN"
  end
end