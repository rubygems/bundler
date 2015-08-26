require "spec_helper"

describe "bundle package" do
  context "with --gemfile" do
    it "finds the gemfile" do
      gemfile bundled_app("NotGemfile"), <<-G
        source "file://#{gem_repo1}"
        gem 'rack'
      G

      bundle "package --gemfile=NotGemfile"

      ENV["BUNDLE_GEMFILE"] = "NotGemfile"
      should_be_installed "rack 1.0.0"
    end
  end

  context "with config path" do
    it "sets root directory for gems" do
      gemfile <<-D
        source "file://#{gem_repo1}"
        gem 'rack'
      D

      bundle "config path #{bundled_app("test")}"
      bundle "package"

      should_be_installed "rack 1.0.0"
      expect(bundled_app("test")).to exist
    end
  end

  context "with --no-install" do
    it "puts the gems in vendor/cache but does not install them" do
      gemfile <<-D
        source "file://#{gem_repo1}"
        gem 'rack'
      D

      bundle "package --no-install"

      should_not_be_installed "rack 1.0.0"
      expect(bundled_app("vendor/cache/rack-1.0.0.gem")).to exist
    end
  end

  context "with --all-platforms" do
    it "puts the gems in vendor/cache even for other rubies", :ruby => "2.1" do
      gemfile <<-D
        source "file://#{gem_repo1}"
        gem 'rack', :platforms => :ruby_19
      D

      bundle "package --all-platforms"
      expect(bundled_app("vendor/cache/rack-1.0.0.gem")).to exist
    end
  end
end

describe "bundle install with gem sources" do
  describe "when cached and locked" do
    it "does not hit the remote at all" do
      build_repo2
      install_gemfile <<-G
        source "file://#{gem_repo2}"
        gem "rack"
      G

      bundle :pack
      simulate_new_machine
      FileUtils.rm_rf gem_repo2

      bundle "install --local"
      should_be_installed "rack 1.0.0"
    end

    it "does not hit the remote at all" do
      build_repo2
      install_gemfile <<-G
        source "file://#{gem_repo2}"
        gem "rack"
      G

      bundle :pack
      simulate_new_machine
      FileUtils.rm_rf gem_repo2

      bundle "install --deployment"

      # See cli/install.rb:L77.
      # FIXME: [user-unfriendly] We must `bundle config path`. Setting
      # `disable_shared_gems` and setting `frozen` to `"1"` are insufficient.
      bundle "config path #{Bundler.settings.path}/vendor/bundle"
      should_be_installed "rack 1.0.0"
    end

    it "does not reinstall already-installed gems" do
      install_gemfile <<-G
        source "file://#{gem_repo1}"
        gem "rack"
      G
      bundle :pack

      build_gem "rack", "1.0.0", :path => bundled_app("vendor/cache") do |s|
        s.write "lib/rack.rb", "raise 'omg'"
      end

      bundle :install
      expect(err).to lack_errors
      should_be_installed "rack 1.0"
    end

    it "ignores cached gems for the wrong platform" do
      simulate_platform "java" do
        install_gemfile <<-G
          source "file://#{gem_repo1}"
          gem "platform_specific"
        G
        bundle :pack
      end

      simulate_new_machine

      simulate_platform "ruby" do
        install_gemfile <<-G
          source "file://#{gem_repo1}"
          gem "platform_specific"
        G
        run "require 'platform_specific' ; puts PLATFORM_SPECIFIC"
        expect(out).to eq("1.0.0 RUBY")
      end
    end

    it "does not update the cache if `bundle cache` is not run" do
      gemfile <<-G
        source "file://#{gem_repo1}"
        gem "rack"
      G
      bundled_app("vendor/cache").mkpath
      expect(bundled_app("vendor/cache").children).to be_empty

      bundle "install"
      expect(bundled_app("vendor/cache").children).to be_empty
    end

    it "updates the cache if `bundle cache` is run" do
      gemfile <<-G
        source "file://#{gem_repo1}"
        gem "rack"
      G
      bundled_app("vendor/cache").mkpath
      expect(bundled_app("vendor/cache").children).to be_empty

      bundle "install"
      bundle "cache"
      expect(bundled_app("vendor/cache").children).not_to be_empty
    end
  end
end
