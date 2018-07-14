# frozen_string_literal: true

RSpec.describe "bundle canonical" do
  before :each do
    install_gemfile <<-G
      source "file://#{gem_repo1}"
      gem "weakling", "~> 0.0.1"
      gem "rack-test", :group => :test
      gem "rack", :groups => [:prod, :test]
    G
  end

  context "with --view option" do
    it "does not update gemfile but displays expected gemfile" do
      bundle! "canonical --view"
      output = <<-G
       source "file://#{gem_repo1}"

       # This is just a fake gem for testing
       gem "weakling", "~> 0.0.1"

       group :prod, :test do
         # This is just a fake gem for testing
         gem "rack"
       end

       group :test do
         # This is just a fake gem for testing
         gem "rack-test"
       end
      G

      expect(out).to eq(strip_whitespace(output))
      gemfile_should_be <<-G
        source "file://#{gem_repo1}"
        gem "weakling", "~> 0.0.1"
        gem "rack-test", :group => :test
        gem "rack", :groups => [:prod, :test]
      G
    end
  end

  context "without --view option" do
    it "updates gemfile" do
      bundle! "canonical"

      gemfile_should_be <<-G
       source "file://#{gem_repo1}"

       # This is just a fake gem for testing
       gem "weakling", "~> 0.0.1"

       group :prod, :test do
         # This is just a fake gem for testing
         gem "rack"
       end

       group :test do
         # This is just a fake gem for testing
         gem "rack-test"
       end
      G
    end
  end
end
