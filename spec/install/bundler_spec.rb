# frozen_string_literal: true
require "spec_helper"

describe "bundle install" do
  describe "with bundler dependencies" do
    before(:each) do
      build_repo2 do
        build_gem "rails", "3.0" do |s|
          s.add_dependency "bundler", ">= 0.9.0.pre"
        end
        build_gem "requires_nonexistant_bunder", "1.0" do |s|
          s.add_dependency "bundler", "= 0.1.1"
        end
        build_gem "bundler", "0.9.1"
        build_gem "bundler", Bundler::VERSION
      end
    end

    it "are forced to the current bundler version" do
      install_gemfile <<-G
        source "file://#{gem_repo2}"
        gem "rails", "3.0"
      G

      should_be_installed "bundler #{Bundler::VERSION}"
    end

    it "are forced to the current bundler version with warnings when no compatible version is found" do
      install_gemfile <<-G
        source "file://#{gem_repo2}"
        gem "requires_nonexistant_bunder"
      G

      expect(out).to include("requires_nonexistant_bunder (1.0) depends on bundler (= 0.1.1), but this Bundler version is #{Bundler::VERSION}")

      should_be_installed "bundler #{Bundler::VERSION}"
    end

    it "are not added if not already present" do
      install_gemfile <<-G
        source "file://#{gem_repo1}"
        gem "rack"
      G
      should_not_be_installed "bundler #{Bundler::VERSION}"
    end

    it "causes a conflict if explicitly requesting a different version" do
      install_gemfile <<-G
        source "file://#{gem_repo2}"
        gem "rails", "3.0"
        gem "bundler", "0.9.2"
      G

      nice_error = <<-E.strip.gsub(/^ {8}/, "")
        Bundler could not find compatible versions for gem "bundler":
          In gems.rb:
            bundler (= 0.9.2)

          Current Bundler version:
            bundler (#{Bundler::VERSION})
        E
      expect(err).to include(nice_error)
    end

    it "works for gems with multiple versions in its dependencies" do
      install_gemfile <<-G
        source "file://#{gem_repo2}"

        gem "multiple_versioned_deps"
      G

      install_gemfile <<-G
        source "file://#{gem_repo2}"

        gem "multiple_versioned_deps"
        gem "rack"
      G

      should_be_installed "multiple_versioned_deps 1.0.0"
    end

    it "includes bundler in the bundle when it's a child dependency" do
      install_gemfile <<-G
        source "file://#{gem_repo2}"
        gem "rails", "3.0"
      G

      run "begin; gem 'bundler'; puts 'WIN'; rescue Gem::LoadError; puts 'FAIL'; end"
      expect(out).to eq("WIN")
    end

    it "allows gem 'bundler' when Bundler is not in the gems.rb or its dependencies" do
      install_gemfile <<-G
        source "file://#{gem_repo2}"
        gem "rack"
      G

      run "begin; gem 'bundler'; puts 'WIN'; rescue Gem::LoadError => e; puts e.backtrace; end"
      expect(out).to eq("WIN")
    end

    it "causes a conflict if child dependencies conflict" do
      install_gemfile <<-G
        source "file://#{gem_repo2}"
        gem "activemerchant"
        gem "rails_fail"
      G

      nice_error = <<-E.strip.gsub(/^ {8}/, "")
        Bundler could not find compatible versions for gem "activesupport":
          In gems.rb:
            activemerchant was resolved to 1.0, which depends on
              activesupport (>= 2.0.0)

            rails_fail was resolved to 1.0, which depends on
              activesupport (= 1.2.3)
      E
      expect(err).to include(nice_error)
    end

    it "causes a conflict if a child dependency conflicts with the gems.rb" do
      install_gemfile <<-G
        source "file://#{gem_repo2}"
        gem "rails_fail"
        gem "activesupport", "2.3.5"
      G

      nice_error = <<-E.strip.gsub(/^ {8}/, "")
        Bundler could not find compatible versions for gem "activesupport":
          In gems.rb:
            activesupport (= 2.3.5)

            rails_fail was resolved to 1.0, which depends on
              activesupport (= 1.2.3)
      E
      expect(err).to include(nice_error)
    end

    it "can install dependencies with newer bundler version" do
      install_gemfile <<-G
        source "file://#{gem_repo2}"
        gem "rails", "3.0"
      G

      simulate_bundler_version "10.0.0"

      bundle "check"
      expect(out).to include("gems.rb's dependencies are satisfied")
    end
  end
end
