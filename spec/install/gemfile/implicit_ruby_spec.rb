# frozen_string_literal: true
require "spec_helper"

describe "implicit ruby requirement" do
  def locked_ruby_version
    Bundler::RubyVersion.from_string(Bundler::LockfileParser.new(lockfile).ruby_version)
  end

  # As discovered by https://github.com/bundler/bundler/issues/4147, there is
  # no test coverage to ensure that adding a gem is possible with a ruby
  # requirement. This test verifies the fix, committed in bfbad5c5.
  it "allows adding gems" do
    install_gemfile <<-G
      source "file://#{gem_repo1}"
      gem "rack"
    G

    expect(locked_ruby_version).to eq(Bundler::RubyVersion.system)

    install_gemfile! <<-G
      source "file://#{gem_repo1}"
      gem "rack"
      gem "rack-obama"
    G

    expect(locked_ruby_version).to eq(Bundler::RubyVersion.system)
    expect(the_bundle).to include_gems "rack-obama 1.0"
  end

  it "allows removing the ruby version requirement" do
    install_gemfile <<-G
      source "file://#{gem_repo1}"
      ruby "~> #{RUBY_VERSION}"
      gem "rack"
    G

    expect(lockfile).to include("RUBY VERSION")

    install_gemfile <<-G
      source "file://#{gem_repo1}"
      gem "rack"
    G

    expect(the_bundle).to include_gems "rack 1.0.0"
    expect(lockfile).to include("RUBY VERSION")
  end

  it "allows changing the ruby version requirement to something compatible" do
    install_gemfile <<-G
      source "file://#{gem_repo1}"
      gem "rack"
    G

    expect(locked_ruby_version).to eq(Bundler::RubyVersion.system)

    simulate_ruby_version "5100"

    install_gemfile <<-G
      source "file://#{gem_repo1}"
      ruby ">= 1.0.1"
      gem "rack"
    G

    expect(the_bundle).to include_gems "rack 1.0.0"
    expect(locked_ruby_version).to eq(Bundler::RubyVersion.system)
  end

  it "allows changing the ruby version requirement to something incompatible" do
    install_gemfile <<-G
      source "file://#{gem_repo1}"
      gem "rack"
    G

    expect(locked_ruby_version).to eq(Bundler::RubyVersion.system)

    simulate_ruby_version "5100"

    install_gemfile <<-G
      source "file://#{gem_repo1}"
      ruby ">= 5000.0"
      gem "rack"
    G

    expect(the_bundle).to include_gems "rack 1.0.0"
    expect(locked_ruby_version.versions).to eq(["5100"])
  end

  it "warns when installing in deployment mode with a mis-match" do
    install_gemfile <<-G
      source "file://#{gem_repo1}"
      gem "rack"
    G

    expect(locked_ruby_version).to eq(system = Bundler::RubyVersion.system)

    simulate_ruby_version "1.0"

    bundle! "install --deployment"
    expect(out).to include("Your Ruby version is 1.0, but your bundled is locked to #{RUBY_VERSION}. This may cause issues if there are any gems that were depending on that ruby version.")
    expect(locked_ruby_version).to eq(system)

    expect(the_bundle).to include_gems "rack 1.0.0"
  end

  it "warns when installing with a lower version" do
    install_gemfile <<-G
      source "file://#{gem_repo1}"
      gem "rack"
    G

    expect(locked_ruby_version).to eq(system = Bundler::RubyVersion.system)

    simulate_ruby_version "1.0"

    bundle! "install"
    expect(out).to include("Your Ruby version is 1.0, but your bundled is locked to #{RUBY_VERSION}. This may cause issues if there are any gems that were depending on that ruby version.")
    expect(locked_ruby_version).to eq(system)

    expect(the_bundle).to include_gems "rack 1.0.0"
  end

  it "does not warn when installing with a higher version" do
    install_gemfile <<-G
      source "file://#{gem_repo1}"
      gem "rack"
    G

    expect(locked_ruby_version).to eq(system = Bundler::RubyVersion.system)

    simulate_ruby_version "5100.3.1415926538"

    bundle! "install"
    expect(out).not_to include("5100.3.1415926538")
    expect(err).not_to include("5100.3.1415926538")
    expect(locked_ruby_version).to eq(system)

    expect(the_bundle).to include_gems "rack 1.0.0"
  end
end
