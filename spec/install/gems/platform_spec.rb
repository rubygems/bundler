require "spec_helper"

describe "bundle install across platforms" do
  it "maintains the same lockfile if all gems are compatible across platforms" do
    lockfile <<-G
      GEM
        remote: file:#{gem_repo1}/
        specs:
          rack (0.9.1)

      PLATFORMS
        #{not_local.first}

      DEPENDENCIES
        rack
    G

    install_gemfile <<-G
      source "file://#{gem_repo1}"

      gem "rack"
    G

    should_be_installed "rack 0.9.1"
  end

  it "pulls in the correct platform specific gem" do
    lockfile <<-G
      GEM
        remote: file:#{gem_repo1}
        specs:
          platform_specific (1.0)

      PLATFORMS
        ruby

      DEPENDENCIES
        platform_specific
    G

    install_gemfile <<-G
      Gem.platforms = [Gem::Platform::RUBY, Gem::Platform.new('#{java}')]
      source "file://#{gem_repo1}"

      gem "platform_specific"
    G

    should_be_installed "platform_specific 1.0 JAVA"
  end

  it "works with gems that have different dependencies" do
    lockfile <<-G
      GEM
        remote: file:#{gem_repo1}
        specs:
          nokogiri (1.4.2)

      PLATFORMS
        ruby

      DEPENDENCIES
        platform_specific
    G

    install_gemfile <<-G
      Gem.platforms = [Gem::Platform::RUBY, Gem::Platform.new('#{java}')]
      source "file://#{gem_repo1}"

      gem "nokogiri"
    G

    should_be_installed "nokogiri 1.4.2 JAVA", "weakling 0.0.3", :platform => "java"

    simulate_new_machine

    install_gemfile <<-G
      Gem.platforms = [Gem::Platform::RUBY]
      source "file://#{gem_repo1}"

      gem "nokogiri"
    G

    should_be_installed "nokogiri 1.4.2"
    should_not_be_installed "weakling"
  end
end

# TODO: Don't make the tests hardcoded to a platform
describe "bundle install with platform conditionals" do
  it "works" do
    install_gemfile <<-G
      source "file://#{gem_repo1}"

      platforms :ruby do
        gem "nokogiri"
      end
    G

    should_be_installed "nokogiri 1.4.2"
  end
end