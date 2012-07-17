require "spec_helper"

%w(cache package).each do |cmd|
  describe "bundle #{cmd} with path" do
    it "is no-op when the path is within the bundle" do
      build_lib "foo", :path => bundled_app("lib/foo")

      install_gemfile <<-G
        gem "foo", :path => '#{bundled_app("lib/foo")}'
      G

      bundle "#{cmd} --all"
      bundled_app("vendor/cache/foo-1.0").should_not exist
      should_be_installed "foo 1.0"
    end

    it "copies when the path is outside the bundle " do
      build_lib "foo"

      install_gemfile <<-G
        gem "foo", :path => '#{lib_path("foo-1.0")}'
      G

      bundle "#{cmd} --all"
      bundled_app("vendor/cache/foo-1.0").should exist
      bundled_app("vendor/cache/foo-1.0/.bundlecache").should be_file

      FileUtils.rm_rf lib_path("foo-1.0")
      should_be_installed "foo 1.0"
    end

    it "updates the path on each cache" do
      build_lib "foo"

      install_gemfile <<-G
        gem "foo", :path => '#{lib_path("foo-1.0")}'
      G

      bundle "#{cmd} --all"

      build_lib "foo" do |s|
        s.write "lib/foo.rb", "puts :CACHE"
      end

      bundle "#{cmd} --all"

      bundled_app("vendor/cache/foo-1.0").should exist
      FileUtils.rm_rf lib_path("foo-1.0")

      run "require 'foo'"
      out.should == "CACHE"
    end

    it "removes stale entries cache" do
      build_lib "foo"

      install_gemfile <<-G
        gem "foo", :path => '#{lib_path("foo-1.0")}'
      G

      bundle "#{cmd} --all"

      install_gemfile <<-G
        gem "bar", :path => '#{lib_path("bar-1.0")}'
      G

      bundle "#{cmd} --all"
      bundled_app("vendor/cache/bar-1.0").should_not exist
    end

    it "raises a warning without --all" do
      build_lib "foo"

      install_gemfile <<-G
        gem "foo", :path => '#{lib_path("foo-1.0")}'
      G

      bundle cmd
      out.should =~ /please pass the \-\-all flag/
      bundled_app("vendor/cache/foo-1.0").should_not exist
    end

    it "stores the given flag" do
      build_lib "foo"

      install_gemfile <<-G
        gem "foo", :path => '#{lib_path("foo-1.0")}'
      G

      bundle "#{cmd} --all"
      build_lib "bar"

      install_gemfile <<-G
        gem "foo", :path => '#{lib_path("foo-1.0")}'
        gem "bar", :path => '#{lib_path("bar-1.0")}'
      G

      bundle cmd
      bundled_app("vendor/cache/bar-1.0").should exist
    end

    it "can rewind chosen configuration" do
      build_lib "foo"

      install_gemfile <<-G
        gem "foo", :path => '#{lib_path("foo-1.0")}'
      G

      bundle "#{cmd} --all"
      build_lib "baz"

      gemfile <<-G
        gem "foo", :path => '#{lib_path("foo-1.0")}'
        gem "baz", :path => '#{lib_path("baz-1.0")}'
      G

      bundle "#{cmd} --no-all"
      bundled_app("vendor/cache/baz-1.0").should_not exist
    end
  end
end