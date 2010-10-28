require "spec_helper"

describe ".bundle/config" do
  before :each do
    gemfile <<-G
      source "file://#{gem_repo1}"
      gem "rack", "1.0.0"
    G
  end

  it "can be moved with an environment variable" do
    ENV['BUNDLE_APP_CONFIG'] = tmp('foo/bar').to_s
    bundle "install --path vendor/bundle"

    bundled_app('.bundle').should_not exist
    tmp('foo/bar/config').should exist
    should_be_installed "rack 1.0.0"
  end

  it "can provide a relative path with the environment variable" do
    FileUtils.mkdir_p bundled_app('omg')
    Dir.chdir bundled_app('omg')

    ENV['BUNDLE_APP_CONFIG'] = "../foo"
    bundle "install --path vendor/bundle"

    bundled_app(".bundle").should_not exist
    bundled_app("../foo/config").should exist
    should_be_installed "rack 1.0.0"
  end

  it "removes environment.rb from BUNDLE_APP_CONFIG's path" do
    FileUtils.mkdir_p(tmp('foo/bar'))
    ENV['BUNDLE_APP_CONFIG'] = tmp('foo/bar').to_s
    bundle "install"
    FileUtils.touch tmp('foo/bar/environment.rb')
    should_be_installed "rack 1.0.0"
    tmp('foo/bar/environment.rb').should_not exist
  end
end
