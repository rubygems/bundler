require "spec_helper"

describe "bundle package" do
  context "with --gemfile" do
    it "finds the gemfile" do
      gemfile bundled_app("NotGemfile"), <<-G
        source "file://#{gem_repo1}"
        gem 'rack'
      G

      bundle "package --gemfile=NotGemfile"

      ENV['BUNDLE_GEMFILE'] = "NotGemfile"
      should_be_installed "rack 1.0.0"
    end
  end

  context "with --path" do
    it "sets root directory for gems" do
      gemfile <<-D
        source "file://#{gem_repo1}"
        gem 'rack'
      D

      bundle "package --path=#{bundled_app('test')}"

      should_be_installed "rack 1.0.0"
      expect(bundled_app("test/vendor/cache/")).to exist
    end
  end
end
