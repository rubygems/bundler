require "spec_helper"
describe "bundle cache" do
  describe "with git sources" do
    it "is silent when the path is within the bundle" do
      build_lib "foo", :path => bundled_app("lib/foo")

      install_gemfile <<-G
        gem "foo", :path => '#{bundled_app("lib/foo")}'
      G

      bundle "cache"
      out.should match /Updating .gem files in vendor\/cache/
    end
  end
end


