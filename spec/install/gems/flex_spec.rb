require File.expand_path('../../../spec_helper', __FILE__)

describe "bundle install --flex" do
  it "installs the gems as expected" do
    flex_install_gemfile <<-G
      source "file://#{gem_repo1}"
      gem 'rack'
    G

    should_be_installed "rack 1.0.0"
    should_be_locked
  end

  it "installs even when the lockfile is invalid" do
    flex_install_gemfile <<-G
      source "file://#{gem_repo1}"
      gem 'rack'
    G

    should_be_installed "rack 1.0.0"
    should_be_locked

    gemfile <<-G
      source "file://#{gem_repo1}"
      gem 'rack', '1.0'
    G

    bundle :flex_install
    should_be_installed "rack 1.0.0"
    should_be_locked
  end

  it "installs added gems without updating previously installed gems" do
    build_repo2

    flex_install_gemfile <<-G
      source "file://#{gem_repo2}"
      gem 'rack'
    G

    update_repo2

    flex_install_gemfile <<-G
      source "file://#{gem_repo2}"
      gem 'rack'
      gem 'activesupport', '2.3.5'
    G

    should_be_installed "rack 1.0.0", 'activesupport 2.3.5'
    should_be_locked
  end
end