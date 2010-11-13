require "spec_helper"

describe "bundle install across platforms" do
  it "maintains the same lockfile if all gems are compatible across platforms" do
    lockfile <<-G
      GEM
        remote: file:#{gem_repo1}/
        specs:
          rack (0.9.1)

      PLATFORMS
        #{not_local}

      DEPENDENCIES
        rack
    G

    install_gemfile <<-G
      source "file://#{gem_repo1}"

      gem "rack"
    G

    should_be_installed "rack 0.9.1"
  end

  it "pulls in the correct platform specific gem" do
    lockfile <<-G
      GEM
        remote: file:#{gem_repo1}
        specs:
          platform_specific (1.0)
          platform_specific (1.0-java)
          platform_specific (1.0-x86-mswin32)

      PLATFORMS
        ruby

      DEPENDENCIES
        platform_specific
    G

    simulate_platform "java"
    install_gemfile <<-G
      source "file://#{gem_repo1}"

      gem "platform_specific"
    G

    should_be_installed "platform_specific 1.0 JAVA"
  end

  it "works with gems that have different dependencies" do
    simulate_platform "java"
    install_gemfile <<-G
      source "file://#{gem_repo1}"

      gem "nokogiri"
    G

    should_be_installed "nokogiri 1.4.2 JAVA", "weakling 0.0.3"

    simulate_new_machine

    simulate_platform "ruby"
    install_gemfile <<-G
      source "file://#{gem_repo1}"

      gem "nokogiri"
    G

    should_be_installed "nokogiri 1.4.2"
    should_not_be_installed "weakling"
  end

  it "works the other way with gems that have different dependencies" do
    simulate_platform "ruby"
    install_gemfile <<-G
      source "file://#{gem_repo1}"

      gem "nokogiri"
    G

    simulate_platform "java"
    bundle "install"

    should_be_installed "nokogiri 1.4.2 JAVA", "weakling 0.0.3"
  end

  it "fetches gems again after changing the version of Ruby" do
    gemfile <<-G
      source "file://#{gem_repo1}"

      gem "rack", "1.0.0"
    G

    bundle "install --path vendor/bundle"

    vendored_gems("gems/rack-1.0.0").should exist
  end

  it "works after switching Rubies" do
    gemfile <<-G
      source "file://#{gem_repo1}"

      gem "rack", "1.0.0"
    G

    bundle "install --path vendor/bundle"

    new_version = Gem::ConfigMap[:ruby_version] == "1.8" ? "1.9.1" : "1.8"
    FileUtils.mv(vendored_gems, bundled_app("vendor/bundle/#{Gem.ruby_engine}/#{new_version}"))

    bundle "install --path ./vendor/bundle"
    vendored_gems("gems/rack-1.0.0").should exist
  end
end

describe "bundle install with platform conditionals" do
  it "installs gems tagged w/ the current platforms" do
    install_gemfile <<-G
      source "file://#{gem_repo1}"

      platforms :#{local_tag} do
        gem "nokogiri"
      end
    G

    should_be_installed "nokogiri 1.4.2"
  end

  it "does not install gems tagged w/ another platforms" do
    install_gemfile <<-G
      source "file://#{gem_repo1}"
      gem "rack"
      platforms :#{not_local_tag} do
        gem "nokogiri"
      end
    G

    should_be_installed     "rack 1.0"
    should_not_be_installed "nokogiri 1.4.2"
  end

  it "installs gems tagged w/ the current platforms inline" do
    install_gemfile <<-G
      source "file://#{gem_repo1}"
      gem "nokogiri", :platforms => :#{local_tag}
    G
    should_be_installed "nokogiri 1.4.2"
  end

  it "does not install gems tagged w/ another platforms inline" do
    install_gemfile <<-G
      source "file://#{gem_repo1}"
      gem "rack"
      gem "nokogiri", :platforms => :#{not_local_tag}
    G
    should_be_installed     "rack 1.0"
    should_not_be_installed "nokogiri 1.4.2"
  end

  it "installs gems tagged w/ the current platform inline" do
    install_gemfile <<-G
      source "file://#{gem_repo1}"
      gem "nokogiri", :platform => :#{local_tag}
    G
    should_be_installed "nokogiri 1.4.2"
  end

  it "doesn't install gems tagged w/ another platform inline" do
    install_gemfile <<-G
      source "file://#{gem_repo1}"
      gem "nokogiri", :platform => :#{not_local_tag}
    G
    should_not_be_installed "nokogiri 1.4.2"
  end

  it "does not blow up on sources with all platform-excluded specs" do
    git = build_git "foo"

    install_gemfile <<-G
      platform :#{not_local_tag} do
        gem "foo", :git => "#{lib_path('foo-1.0')}"
      end
    G

    bundle :show, :exitstatus => true
    exitstatus.should == 0
  end

end
