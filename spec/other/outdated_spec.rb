require "spec_helper"

describe "bundle outdated" do

  before :each do
    build_repo2 do
      build_git "foo", :path => lib_path("foo")
    end

    install_gemfile <<-G
      source "file://#{gem_repo2}"
      gem "activesupport", "2.3.5"
      gem "foo", :git => "#{lib_path('foo')}"
    G
  end

  describe "with no arguments" do
    it "returns list of outdated gems" do
      update_repo2 do
        build_gem "activesupport", "3.0"
        update_git "foo", :path => lib_path("foo")
      end

      bundle "outdated"
      expect(out).to include("activesupport (3.0 > 2.3.5)")
      expect(out).to include("foo (1.0")
    end

    it "returns non zero exit status if outdated gems present" do
      update_repo2 do
        build_gem "activesupport", "3.0"
        update_git "foo", :path => lib_path("foo")
      end

      bundle "outdated", :exitstatus => true

      expect(exitstatus).to_not be_zero
    end

    it "returns success exit status if no outdated gems present" do
      bundle "outdated", :exitstatus => true

      expect(exitstatus).to be_zero
    end
  end

  describe "with --local option" do
    it "doesn't hit repo2" do
      FileUtils.rm_rf(gem_repo2)

      bundle "outdated --local"
      expect(out).not_to match(/Fetching/)
    end
  end

  describe "with specified gems" do
    it "returns list of outdated gems" do
      update_repo2 do
        build_gem "activesupport", "3.0"
        update_git "foo", :path => lib_path("foo")
      end

      bundle "outdated foo"
      expect(out).not_to include("activesupport (3.0 > 2.3.5)")
      expect(out).to include("foo (1.0")
    end
  end

  describe "pre-release gems" do
    context "without the --pre option" do
      it "ignores pre-release versions" do
        update_repo2 do
          build_gem "activesupport", "3.0.0.beta"
        end

        bundle "outdated"
        expect(out).not_to include("activesupport (3.0.0.beta > 2.3.5)")
      end
    end

    context "with the --pre option" do
      it "includes pre-release versions" do
        update_repo2 do
          build_gem "activesupport", "3.0.0.beta"
        end

        bundle "outdated --pre"
        expect(out).to include("activesupport (3.0.0.beta > 2.3.5)")
      end
    end

    context "when current gem is a pre-release" do
      it "includes the gem" do
        update_repo2 do
          build_gem "activesupport", "3.0.0.beta.1"
          build_gem "activesupport", "3.0.0.beta.2"
        end

        install_gemfile <<-G
          source "file://#{gem_repo2}"
          gem "activesupport", "3.0.0.beta.1"
        G

        bundle "outdated"
        expect(out).to include("activesupport (3.0.0.beta.2 > 3.0.0.beta.1)")
      end
    end
  end

end
