require "spec_helper"

describe "bundle flex_install" do
  it "installs the gems as expected" do
    install_gemfile <<-G
      source "file://#{gem_repo1}"
      gem 'rack'
    G

    should_be_installed "rack 1.0.0"
    should_be_locked
  end

  it "installs even when the lockfile is invalid" do
    install_gemfile <<-G
      source "file://#{gem_repo1}"
      gem 'rack'
    G

    should_be_installed "rack 1.0.0"
    should_be_locked

    gemfile <<-G
      source "file://#{gem_repo1}"
      gem 'rack', '1.0'
    G

    bundle :install
    should_be_installed "rack 1.0.0"
    should_be_locked
  end

  it "keeps child dependencies at the same version" do
    build_repo2

    install_gemfile <<-G
      source "file://#{gem_repo2}"
      gem "rack-obama"
    G

    should_be_installed "rack 1.0.0", "rack-obama 1.0.0"

    update_repo2
    install_gemfile <<-G
      source "file://#{gem_repo2}"
      gem "rack-obama", "1.0"
    G

    should_be_installed "rack 1.0.0", "rack-obama 1.0.0"
  end

  describe "adding new gems" do
    it "installs added gems without updating previously installed gems" do
      build_repo2

      install_gemfile <<-G
        source "file://#{gem_repo2}"
        gem 'rack'
      G

      update_repo2

      install_gemfile <<-G
        source "file://#{gem_repo2}"
        gem 'rack'
        gem 'activesupport', '2.3.5'
      G

      should_be_installed "rack 1.0.0", 'activesupport 2.3.5'
    end

    it "keeps child dependencies pinned" do
      build_repo2

      install_gemfile <<-G
        source "file://#{gem_repo2}"
        gem "rack-obama"
      G

      update_repo2

      install_gemfile <<-G
        source "file://#{gem_repo2}"
        gem "rack-obama"
        gem "thin"
      G

      should_be_installed "rack 1.0.0", 'rack-obama 1.0', 'thin 1.0'
    end
  end

  describe "removing gems" do
    it "removes gems without changing the versions of remaining gems" do
      build_repo2
      install_gemfile <<-G
        source "file://#{gem_repo2}"
        gem 'rack'
        gem 'activesupport', '2.3.5'
      G

      update_repo2

      install_gemfile <<-G
        source "file://#{gem_repo2}"
        gem 'rack'
      G

      should_be_installed "rack 1.0.0"
      should_not_be_installed "activesupport 2.3.5"

      install_gemfile <<-G
        source "file://#{gem_repo2}"
        gem 'rack'
        gem 'activesupport', '2.3.2'
      G

      should_be_installed "rack 1.0.0", 'activesupport 2.3.2'
    end

    it "removes top level dependencies when removed from the Gemfile while leaving other dependencies intact" do
      build_repo2
      install_gemfile <<-G
        source "file://#{gem_repo2}"
        gem 'rack'
        gem 'activesupport', '2.3.5'
      G

      update_repo2

      install_gemfile <<-G
        source "file://#{gem_repo2}"
        gem 'rack'
      G

      should_not_be_installed "activesupport 2.3.5"
    end

    it "removes child dependencies" do
      build_repo2
      install_gemfile <<-G
        source "file://#{gem_repo2}"
        gem 'rack-obama'
        gem 'activesupport'
      G

      should_be_installed "rack 1.0.0", "rack-obama 1.0.0", "activesupport 2.3.5"

      update_repo2
      install_gemfile <<-G
        source "file://#{gem_repo2}"
        gem 'activesupport'
      G

      should_be_installed 'activesupport 2.3.5'
      should_not_be_installed "rack-obama", "rack"
    end
  end
end