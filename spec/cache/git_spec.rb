require "spec_helper"
describe "bundle cache" do
  describe "with git sources" do
    it "is silent when the path is within the bundle" do
      build_git "foo", :path => "file://#{lib_path('foo')}/.git"

      install_gemfile <<-G
        gem "foo", :git => "file://#{lib_path('foo')}/.git"
      G
      bundle "install"
      bundle "cache"
      out.should match /Updating .gem files in vendor\/cache/
    end

    it "locks the gemfile" do
      build_git "foo", :path => "file://#{lib_path('foo')}/.git"

      install_gemfile <<-G
        gem "foo", :git => "file://#{lib_path('foo')}/.git"
      G

      bundle "cache"
      bundled_app("Gemfile.lock").should exist
    end

    it "caches the gems" do
      build_git "foo", :path => "file://#{lib_path('foo')}/.git"

      install_gemfile <<-G
        gem "foo", :git => "file://#{lib_path('foo')}/.git"
      G

      bundle "cache"
      pending "resolution of Bundler issue #67 (Github)" do
        bundled_app("vendor/cache/foo-1.0.0.gem").should exist
      end
    end
  end
end


