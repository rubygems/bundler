require File.expand_path('../../spec_helper', __FILE__)

describe "bundle lock with git" do
  before :each do
    build_git "foo"

    install_gemfile <<-G
      git "#{lib_path('foo-1.0')}"
      gem 'foo'
    G

    bundle :lock
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
    rev = revision_for(lib_path("foo-1.0"))
    gem_path = "foo-1.0-5b89e78c95d2131a78cc39dab852b6266f4bed9d-#{rev}"
    full_gem_path = Bundler.install_path.join(gem_path).to_s

    run <<-RUBY
      puts Bundler::SPECS.map{|s| s.full_gem_path }
    RUBY
    out.should == full_gem_path
  end
end