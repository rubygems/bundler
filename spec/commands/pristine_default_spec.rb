# frozen_string_literal: true

RSpec.describe "bundle pristine", :ruby_repo do
  context "with default gems" do
    let(:default_irb_version) { ruby "gem 'irb', '< 999999'; require 'irb'; puts IRB::VERSION" }

    it "doesn't error" do
      skip "irb isn't a default gem" if default_irb_version.empty?

      build_repo2 do
        build_gem "irb", "#{default_irb_version}"
      end

      install_gemfile! <<-G
        source "#{file_uri_for(gem_repo2)}"

        gem "irb"
      G

      bundle "pristine"

      expect(out).to match(/Installing irb/)
      expect(err).to be_empty
    end
  end
end
