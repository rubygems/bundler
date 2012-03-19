require "spec_helper"

describe "bundle cache" do
  describe "with path sources" do
    it "is no-op when the path is within the bundle" do
      build_lib "foo", :path => bundled_app("lib/foo")

      install_gemfile <<-G
        gem "foo", :path => '#{bundled_app("lib/foo")}'
      G

      bundle "cache"
      bundled_app("vendor/cache/foo-1.0").should_not exist

      out.should == "Updating .gem files in vendor/cache"
      should_be_installed "foo 1.0"
    end

    it "copies when the path is outside the bundle " do
      build_lib "foo"

      install_gemfile <<-G
        gem "foo", :path => '#{lib_path("foo-1.0")}'
      G

      bundle "cache"
      bundled_app("vendor/cache/foo-1.0").should exist

      FileUtils.rm_rf lib_path("foo-1.0")
      out.should == "Updating .gem files in vendor/cache"
      should_be_installed "foo 1.0"
    end
  end
end
