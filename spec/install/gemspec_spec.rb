require "spec_helper"

describe "bundle install from an existing gemspec" do

  before(:each) do
    build_gem "bar", :to_system => true
    build_gem "bar-dev", :to_system => true
  end

  it "should install runtime and development dependencies" do
    build_lib("foo", :path => tmp.join("foo")) do |s|
      s.write("Gemfile", "source :rubygems\ngemspec")
      s.add_dependency "bar", "=1.0.0"
      s.add_development_dependency "bar-dev", '=1.0.0'
    end
    install_gemfile <<-G
      source "file://#{gem_repo2}"
      gemspec :path => '#{tmp.join("foo")}'
    G

    should_be_installed "bar 1.0.0"
    should_be_installed "bar-dev 1.0.0", :groups => :development
  end

  it "should handle a list of requirements" do
    build_gem "baz", "1.0", :to_system => true
    build_gem "baz", "1.1", :to_system => true

    build_lib("foo", :path => tmp.join("foo")) do |s|
      s.write("Gemfile", "source :rubygems\ngemspec")
      s.add_dependency "baz", ">= 1.0", "< 1.1"
    end
    install_gemfile <<-G
      source "file://#{gem_repo2}"
      gemspec :path => '#{tmp.join("foo")}'
    G

    should_be_installed "baz 1.0"
  end

  it "should raise if there are no gemspecs available" do
    build_lib("foo", :path => tmp.join("foo"), :gemspec => false)

    error = install_gemfile(<<-G, :expect_err => true)
      source "file://#{gem_repo2}"
      gemspec :path => '#{tmp.join("foo")}'
    G
    error.should match(/There are no gemspecs at #{tmp.join('foo')}/)
  end

  it "should raise if there are too many gemspecs available" do
    build_lib("foo", :path => tmp.join("foo")) do |s|
      s.write("foo2.gemspec", "")
    end

    error = install_gemfile(<<-G, :expect_err => true)
      source "file://#{gem_repo2}"
      gemspec :path => '#{tmp.join("foo")}'
    G
    error.should match(/There are multiple gemspecs at #{tmp.join('foo')}/)
  end

  it "should pick a specific gemspec" do
    build_lib("foo", :path => tmp.join("foo")) do |s|
      s.write("foo2.gemspec", "")
      s.add_dependency "bar", "=1.0.0"
      s.add_development_dependency "bar-dev", '=1.0.0'
    end

    install_gemfile(<<-G, :expect_err => true)
      source "file://#{gem_repo2}"
      gemspec :path => '#{tmp.join("foo")}', :name => 'foo'
    G

    should_be_installed "bar 1.0.0"
    should_be_installed "bar-dev 1.0.0", :groups => :development
  end

  it "should use a specific group for development dependencies" do
    build_lib("foo", :path => tmp.join("foo")) do |s|
      s.write("foo2.gemspec", "")
      s.add_dependency "bar", "=1.0.0"
      s.add_development_dependency "bar-dev", '=1.0.0'
    end

    install_gemfile(<<-G, :expect_err => true)
      source "file://#{gem_repo2}"
      gemspec :path => '#{tmp.join("foo")}', :name => 'foo', :development_group => :dev
    G

    should_be_installed "bar 1.0.0"
    should_not_be_installed "bar-dev 1.0.0", :groups => :development
    should_be_installed "bar-dev 1.0.0", :groups => :dev
  end

end
