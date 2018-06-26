# frozen_string_literal: true

RSpec.describe "bundle change" do
  before :each do
    install_gemfile <<-G
      source "file://#{gem_repo2}"

      gem "rack", '~> 1.0.0', :group => [:dev]

      group :test do
        gem "minitest"
        gem "rspec"
      end
    G
  end

  describe "when gem is not present" do
    it "throws error" do
      bundle "change rake --group dev1"

      expect(out).to include("`rake` could not be found in the Gemfile.")
    end
  end

  context "without options" do
    it "throws error" do
      bundle "change rack"

      expect(out).to include("Please supply atleast one option to change.")
    end
  end

  describe "with --group option" do
    context "when group is present as inline" do
      it "changes group of the gem" do
        bundle! "change rack --group dev1"

        expect(bundled_app("Gemfile").read).to include("gem \"rack\", '~> 1.0.0', :group => [:dev1]")
      end
    end

    context "when gem is present in the group block" do
      it "removes gem from the block" do
        bundle! "change minitest --group test1"

        gemfile_should_be <<-G
          source "file://#{gem_repo2}"

          gem "rack", '~> 1.0.0', :group => [:dev]

          gem "minitest", :group => [:test1]

          group :test do
            gem "rspec"
          end
        G
      end
    end
  end

  describe "with --version option" do
    context "when specified version exists" do
      it "changes version of the gem" do
        bundle! "change rack --version 1.0.1"

        expect(bundled_app("Gemfile").read).to include("gem \"rack\", '~> 1.0.1', :group => [:dev]")
      end
    end

    context "when specified version does not exist" do
      it "throws error" do
        bundle! "change rack --version 42.0.0"

        expect(bundled_app("Gemfile").read).to include("gem \"rack\", '~> 1.0.0', :group => [:dev]")
        expect(out).to include("Could not find gem 'rack (= 42.0.0)' in rubygems repository")
      end
    end
  end
end
