require 'spec_helper'
require 'bundler/rubygems_ext'

describe Gem::Dependency do
  describe "#all_deps" do
    it "returns deps" do
      install_gemfile  <<-G
        source "file://#{gem_repo1}"

        gem "thin"
      G

      ruby <<-G
        require "bundler/rubygems_ext"
        dep = Gem::Dependency.new("thin")
        print dep.all_deps.map(&:name).sort.join(",")
      G

      expect(out).to eq("rack,thin")
    end

    it "returns unique deps" do
      install_gemfile  <<-G
        source "file://#{gem_repo1}"

        gem "rails"
      G

      ruby <<-G
        require "bundler/rubygems_ext"
        dep = Gem::Dependency.new("rails")
        print dep.all_deps.map(&:name).sort.join(",")
      G

      expect(out).to eq(
        %w(rails rake actionpack activerecord actionmailer activeresource activesupport).sort.join(","))
    end
  end
end
