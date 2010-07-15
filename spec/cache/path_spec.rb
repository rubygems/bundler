require "spec_helper"

describe "bundle cache" do
  describe "with path sources" do
    it "is silent when the path is within the bundle" do
      build_lib "foo", :path => bundled_app("lib/foo")

      install_gemfile <<-G
        gem "foo", :path => '#{bundled_app("lib/foo")}'
      G

      bundle "cache"
      out.should == "Updating .gem files in vendor/cache"
    end

    it "warns when the path is outside of the bundle" do
      build_lib "foo"

      install_gemfile <<-G
        gem "foo", :path => '#{lib_path("foo-1.0")}'
      G

      bundle "cache"
      out.should include("foo at `#{lib_path("foo-1.0")}` will not be cached")
    end
  end
end
