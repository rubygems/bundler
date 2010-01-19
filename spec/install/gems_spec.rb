require File.expand_path('../../spec_helper', __FILE__)

describe "bbl install with gem sources" do
  before :each do
    in_app_root
  end

  it "fetches gems" do
    install_gemfile <<-G
      gem 'rack'
    G

    should_be_installed("rack 1.0.0")
  end

  it "pulls in dependencies" do
    install_gemfile <<-G
      gem "rails"
    G

    should_be_installed "actionpack 2.3.2", "rails 2.3.2"
  end

  it "does the right version" do
    install_gemfile <<-G
      gem "rack", "0.9.1"
    G

    should_be_installed "rack 0.9.1"
  end

  it "resolves correctly" do
    install_gemfile <<-G
      gem "activemerchant"
      gem "rails"
    G

    should_be_installed "activemerchant 1.0", "activesupport 2.3.2", "actionpack 2.3.2"
  end

  it "activates gem correctly according to the resolved gems" do
    install_gemfile <<-G
      gem "activesupport", "2.3.5"
    G

    install_gemfile <<-G
      gem "activemerchant"
      gem "rails"
    G

    should_be_installed "activemerchant 1.0", "activesupport 2.3.2", "actionpack 2.3.2"
  end

  describe "when locked" do

    it "works" do
      system_gems "rack-1.0.0" do
        gemfile <<-G
          gem "rack"
        G

        bbl :lock
      end

      system_gems [] do
        bbl :install
        should_be_installed "rack 1.0.0"
      end
    end

  end
end