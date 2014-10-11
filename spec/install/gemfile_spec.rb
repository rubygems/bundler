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

  context "with future features" do
    context "when source is used with a block" do
      it "reports that sources with a block is not supported" do
        gemfile <<-G
          source 'http://rubygems.example.org' do
            gem 'rack'
          end
        G

        bundle :install
        expect(out).to match(/A block was passed to `source`/)
      end
    end

    context "when source is used without a block" do
      it "prints no warnings" do
        gemfile <<-G
          source 'http://rubygems.example.org'
        G

        bundle :install
        expect(out).not_to match(/A block was passed to `source`/)
      end
    end
  end
end
