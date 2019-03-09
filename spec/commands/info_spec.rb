# frozen_string_literal: true

RSpec.describe "bundle info" do
  context "info from specific gem in gemfile" do
    before do
      install_gemfile <<-G
        source "file://#{gem_repo1}"
        gem "rails"
      G
    end

    it "prints information if gem exists in bundle" do
      bundle "info rails"
      expect(out).to include "* rails (2.3.2)
\tSummary: This is just a fake gem for testing
\tHomepage: http://example.com
\tPath: #{default_bundle_path("gems", "rails-2.3.2")}"
    end

    it "complains if gem not in bundle" do
      bundle "info missing"
      expect(err).to eq("Could not find gem 'missing'.")
    end

    context "given a default gem shippped in ruby", :ruby_repo do
      it "prints information about the default gem", :if => (RUBY_VERSION >= "2.0") do
        bundle "info rdoc"
        expect(out).to include("* rdoc")
        expect(out).to include("Default Gem: yes")
      end
    end

    context "when gem does not have homepage" do
      before do
        build_repo2 do
          build_gem "rails", "2.3.2" do |s|
            s.executables = "rails"
            s.summary = "Just another test gem"
          end
        end
      end

      it "excludes the homepage field from the output" do
        expect(out).to_not include("Homepage:")
      end
    end
  end
end
