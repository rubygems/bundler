require "spec_helper"

describe "bundle lock with git gems" do
  before :each do
    build_git "foo"

    install_gemfile <<-G
      gem 'foo', :git => "#{lib_path('foo-1.0')}"
    G
  end

  it "doesn't break right after running lock" do
    should_be_installed "foo 1.0.0"
  end

  it "locks a git source to the current ref" do
    update_git "foo"
    bundle :install

    run <<-RUBY
      require 'foo'
      puts "WIN" unless defined?(FOO_PREV_REF)
    RUBY

    out.should == "WIN"
  end

  it "provides correct #full_gem_path" do
    run <<-RUBY
      puts Gem.source_index.find_name('foo').first.full_gem_path
    RUBY
    out.should == bundle("show foo")
  end

end
