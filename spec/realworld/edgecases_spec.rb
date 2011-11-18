require 'spec_helper'

describe "real world edgecases", :realworld => true do
  # there is no rbx-relative-require gem that will install on 1.9
  it "ignores extra gems with bad platforms", :ruby => "1.8" do
    install_gemfile <<-G
      source :rubygems
      gem "linecache", "0.46"
    G
    err.should eq("")
  end

  # https://github.com/carlhuda/bundler/issues/1202
  it "bundle cache works with rubygems 1.3.7 and pre gems" do
    install_gemfile <<-G
      source :rubygems
      gem "rack", "1.3.0.beta2"
    G
    bundle :cache
    out.should_not include("Removing outdated .gem files from vendor/cache")
  end

  # https://github.com/carlhuda/bundler/issues/1486
  # this is a hash collision that only manifests on 1.8.7
  it "finds the correct child versions" do
    install_gemfile <<-G
      source :rubygems

      gem 'i18n', '~> 0.4'
      gem 'activesupport', '~> 3.0'
      gem 'activerecord', '~> 3.0'
      gem 'builder', '~> 2.1.2'
    G
    out.should include("activemodel (3.0.5)")
  end

  # https://github.com/carlhuda/bundler/issues/1500
  it "does not fail install because of gem plugins" do
    realworld_system_gems("open_gem --version 1.4.2", "rake --version 0.9.2")
    gemfile <<-G
      source :rubygems

      gem 'rack', '1.0.0'
    G

    bundle "install --path vendor/bundle", :expect_err => true
    err.should_not include("Could not find rake")
    err.should be_empty
  end
end
