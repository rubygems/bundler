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
end