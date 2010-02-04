require File.expand_path('../../spec_helper', __FILE__)

describe "gemfile install with git sources" do
  it "fetches gems" do
    build_lib "foo"

    install_gemfile <<-G
      path "#{lib_path('foo-1.0')}"
      gem 'foo'
    G

    should_be_installed("foo 1.0")
  end

  it "supports pinned paths" do
    build_lib "foo"

    install_gemfile <<-G
      gem 'foo', :path => "#{lib_path('foo-1.0')}"
    G

    should_be_installed("foo 1.0")
  end

  it "installs dependencies from the path even if a newer gem is available elsewhere" do
    system_gems "rack-1.0.0"

    build_lib "rack", "1.0", :path => lib_path('nested/bar') do |s|
      s.write "lib/rack.rb", "puts 'WIN OVERRIDE'"
    end

    build_lib "foo", :path => lib_path('nested') do |s|
      s.add_dependency "rack", "= 1.0"
    end

    install_gemfile <<-G
      source "file://#{gem_repo1}"
      gem "foo", :path => "#{lib_path('nested')}"
    G

    run "require 'rack'"
    out.should == 'WIN OVERRIDE'
  end

  it "works" do
    build_gem "foo", "1.0.0", :to_system => true do |s|
      s.write "lib/foo.rb", "puts 'FAIL'"
    end

    build_lib "omg", "1.0", :path => lib_path("omg") do |s|
      s.add_dependency "foo"
    end

    build_lib "foo", "1.0.0", :path => lib_path("omg/foo")

    install_gemfile <<-G
      gem "omg", :path => "#{lib_path('omg')}"
    G

    should_be_installed "foo 1.0"
  end

  describe "when locked" do
    it "keeps source pinning" do
      build_lib "foo", "1.0", :path => lib_path('foo')
      build_lib "omg", "1.0", :path => lib_path('omg')
      build_lib "foo", "1.0", :path => lib_path('omg/foo') do |s|
        s.write "lib/foo.rb", "puts 'FAIL'"
      end

      install_gemfile <<-G
        gem "foo", :path => "#{lib_path('foo')}"
        gem "omg", :path => "#{lib_path('omg')}"
      G

      bundle :lock

      should_be_installed "foo 1.0"
    end
  end
end