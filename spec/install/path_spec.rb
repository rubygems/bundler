require "spec_helper"

describe "bundle install with explicit source paths" do
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

  it "supports relative paths" do
    build_lib "foo"

    relative_path = lib_path('foo-1.0').relative_path_from(Pathname.new(Dir.pwd))

    install_gemfile <<-G
      gem 'foo', :path => "#{relative_path}"
    G

    should_be_installed("foo 1.0")
  end

  it "expands paths" do
    build_lib "foo"

    relative_path = lib_path('foo-1.0').relative_path_from(Pathname.new("~").expand_path)

    install_gemfile <<-G
      gem 'foo', :path => "~/#{relative_path}"
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

  it "sets up executables" do
    pending_jruby_shebang_fix

    build_lib "foo" do |s|
      s.executables = "foobar"
    end

    install_gemfile <<-G
      path "#{lib_path('foo-1.0')}"
      gem 'foo'
    G

    bundle "exec foobar"
    out.should == "1.0"
  end

  it "removes the .gem file after installing" do
    build_lib "foo"

    install_gemfile <<-G
      gem 'foo', :path => "#{lib_path('foo-1.0')}"
    G

    lib_path('foo-1.0').join('foo-1.0.gem').should_not exist
  end

  describe "block syntax" do
    it "pulls all gems from a path block" do
      build_lib "omg"
      build_lib "hi2u"

      install_gemfile <<-G
        path "#{lib_path}" do
          gem "omg"
          gem "hi2u"
        end
      G

      should_be_installed "omg 1.0", "hi2u 1.0"
    end
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

    it "works when the path does not have a gemspec" do
      build_lib "foo", :gemspec => false

      gemfile <<-G
        gem "foo", "1.0", :path => "#{lib_path('foo-1.0')}"
      G

      should_be_installed "foo 1.0"

      bundle :lock

      should_be_installed "foo 1.0"
    end
  end
end
