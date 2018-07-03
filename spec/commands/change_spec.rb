# frozen_string_literal: true

RSpec.describe "bundle change" do
  before :each do
    install_gemfile <<-G
      source "file://#{gem_repo1}"

      gem "rack", "~> 1.0", :group => [:dev]
      gem "weakling", ">=  0.0.1"

      group :test do
        gem "rack-test", "= 1.0"
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

      expect(out).to include("Please supply at least one option to change.")
    end
  end

  describe "with --group option" do
    context "when group is present as inline" do
      it "changes group of the gem" do
        bundle! "change rack --group dev1"

        gemfile_should_be <<-G
          source "file://#{gem_repo1}"

          gem "weakling", ">=  0.0.1"

          group :test do
            gem "rack-test", "= 1.0"
            gem "rspec"
          end

          gem "rack", "~> 1.0", :group => [:dev1]
        G
      end
    end

    context "when gem is present in the group block" do
      it "removes gem from the block" do
        bundle! "change rack-test --group test1"

        gemfile_should_be <<-G
          source "file://#{gem_repo1}"

          gem "rack", "~> 1.0", :group => [:dev]
          gem "weakling", ">=  0.0.1"

          group :test do
            gem "rspec"
          end

          gem "rack-test", "= 1.0", :group => [:test1]
        G
      end
    end

    context "when mutiple groups are specified" do
      it "adds mutiple groups" do
        bundle! "change rack --group=dev,dev1"

        gemfile_should_be <<-G
          source "file://#{gem_repo1}"

          gem "weakling", ">=  0.0.1"

          group :test do
            gem "rack-test", "= 1.0"
            gem "rspec"
          end

          gem "rack", "~> 1.0", :groups => [:dev, :dev1]
        G
      end
    end

    context "when gem is already in one or more groups" do
      it "shows warning that gem is present" do
        bundle! "change rack --group=dev,dev1"

        expect(out).to include("`rack` is already present in `dev`")
        gemfile_should_be <<-G
          source "file://#{gem_repo1}"

          gem "weakling", ">=  0.0.1"

          group :test do
            gem "rack-test", "= 1.0"
            gem "rspec"
          end

          gem "rack", "~> 1.0", :groups => [:dev, :dev1]
        G
      end
    end
  end

  describe "with --version option" do
    context "when specified version exists" do
      it "changes version of the gem" do
        bundle! "change rack --version 0.9.1"

        expect(bundled_app("Gemfile").read).to include("gem \"rack\", \"~> 0.9.1\", :group => [:dev]")
      end
    end

    context "when specified version does not exist" do
      it "throws error" do
        bundle! "change rack --version 42.0.0"

        expect(bundled_app("Gemfile").read).to include("gem \"rack\", \"~> 1.0\", :group => [:dev]")
        expect(out).to include("Could not find gem 'rack (= 42.0.0)'")
      end
    end

    context "when other options are updated for gem whose version requirements are not specified" do
      it "adds pessimistic version to gem" do
        bundle! "change rspec --group test1"

        expect(bundled_app("Gemfile").read).to include("gem \"rspec\", \"~> 1.2\", :group => [:test1]")
      end
    end

    context "when other options are changed for gem which has optimistic version requirement" do
      it "retains the optimistic version prefix" do
        bundle! "change weakling --group dev1"

        expect(bundled_app("Gemfile").read).to include("gem \"weakling\", \">= 0.0.3\", :group => [:dev1]")
      end
    end
  end

  describe "with --source option" do
    context "when source uri is correct" do
      it "changes source uri of the gem" do
        build_repo2
        bundle! "change rack --source=file://#{gem_repo2}"

        expect(bundled_app("Gemfile").read).to include("gem \"rack\", \"~> 1.0\", :group => [:dev], :source => \"file://#{gem_repo2}\"")
      end
    end
  end
end
