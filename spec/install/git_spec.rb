require File.expand_path('../../spec_helper', __FILE__)

describe "bbl install with git sources" do
  before :each do
    in_app_root

    build_git "foo"

    install_gemfile <<-G
      git "#{lib_path('foo-1.0')}"
      gem 'foo'
    G
  end

  it "fetches gems" do
    should_be_installed("foo 1.0")

    run <<-RUBY
      require 'foo'
      puts "WIN" unless defined?(FOO_PREV_REF)
    RUBY

    out.should == "WIN"
  end

  it "floats on master if no ref is specified" do
    update_git "foo"

    in_app_root2 do
      install_gemfile <<-G
        git "#{lib_path('foo-1.0')}"
        gem 'foo'
      G
    end

    run <<-RUBY
      require 'foo'
      puts "WIN" if defined?(FOO_PREV_REF)
    RUBY

    out.should == "WIN"
  end
end