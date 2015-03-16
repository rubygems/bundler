require "spec_helper"

describe "bundle install" do

  context "with duplicated gems" do
    it "will display a warning" do
      install_gemfile <<-G
        gem 'rails', '~> 4.0.0'
        gem 'rails', '~> 4.0.0'
      G
      expect(out).to include("more than once")
    end
  end

  context "with --gemfile" do
    it "finds the gemfile" do
      gemfile bundled_app("NotGemfile"), <<-G
        source "file://#{gem_repo1}"
        gem 'rack'
      G

      bundle :install, :gemfile => bundled_app("NotGemfile")

      ENV['BUNDLE_GEMFILE'] = "NotGemfile"
      should_be_installed "rack 1.0.0"
    end
  end

  context "with gemfile set via config" do
    before do
      gemfile bundled_app("NotGemfile"), <<-G
        source "file://#{gem_repo1}"
        gem 'rack'
      G

      bundle "config --local gemfile #{bundled_app("NotGemfile")}"
    end
    it "uses the gemfile to install" do
      bundle "install"
      bundle "show"

      expect(out).to include("rack (1.0.0)")
    end
    it "uses the gemfile while in a subdirectory" do
      bundled_app("subdir").mkpath
      Dir.chdir(bundled_app("subdir")) do
        bundle "install"
        bundle "show"

        expect(out).to include("rack (1.0.0)")
      end
    end
  end

  context "with deprecated features" do
    before :each do
      in_app_root
    end

    it "reports that lib is an invalid option" do
      gemfile <<-G
        gem "rack", :lib => "rack"
      G

      bundle :install
      expect(out).to match(/You passed :lib as an option for gem 'rack', but it is invalid/)
    end
  end

  context "with a post_install hook" do
    before :each do
      in_app_root
    end

    it "runs with no arguments" do
      gemfile <<-G
        source "file://#{gem_repo1}"
        gem "rack"
        post_install { puts "POST INSTALL RAN" }
      G

      bundle :install
      expect(out).to match(/POST INSTALL RAN/)
    end

    it "passes in the root and specs by group" do
      gemfile <<-G
        source "file://#{gem_repo1}"
        gem "rack"
        post_install do |root, specs_by_group|
          puts "POST INSTALL \#{root}"
          puts 'POST INSTALL ' + specs_by_group.keys.join(' ')
          puts 'POST INSTALL ' + specs_by_group.values.flatten.map(&:name).join(' ')
        end
      G

      bundle :install
      expect(out).to include("POST INSTALL #{Bundler.root}")
      expect(out).to include("POST INSTALL default")
      expect(out).to include("POST INSTALL bundler rack")
    end
  end

end
