# frozen_string_literal: true

RSpec.describe "bundle install" do
  context "with gem sources" do
    context "when gems include a fund URI" do
      it "should display the plural fund message after installing" do
        gemfile <<-G
          source "#{file_uri_for(gem_repo1)}"
          gem 'has_metadata'
          gem 'has_funding'
          gem 'rack-obama'
        G

        bundle :install
        expect(out).to include("2 gems you depend on are looking for funding!")
      end

      it "should display the singular fund message after installing" do
        gemfile <<-G
          source "#{file_uri_for(gem_repo1)}"
          gem 'has_funding'
          gem 'rack-obama'
        G

        bundle :install
        expect(out).to include("1 gem you depend on is looking for funding!")
      end
    end

    context "when gems do not include fund messages" do
      it "should not display any fund messages" do
        gemfile <<-G
          source "#{file_uri_for(gem_repo1)}"
          gem "activesupport"
        G

        bundle :install
        expect(out).not_to include("gem you depend on")
      end
    end

    context "when a dependecy includes a fund message" do
      it "should not display the fund message" do
        gemfile <<-G
          source "#{file_uri_for(gem_repo1)}"
          gem 'gem_with_dependent_funding'
        G

        bundle :install
        expect(out).not_to include("gem you depend on")
      end
    end
  end

  context "with git sources" do
    context "when gems include fund URI" do
      it "should display the fund URI after installing" do
        build_git "also_has_funding" do |s|
          s.metadata = {
            "funding_uri" => "https://example.com/also_has_funding/funding",
          }
        end
        gemfile <<-G
          source "#{file_uri_for(gem_repo1)}"
          gem 'also_has_funding', :git => '#{lib_path("also_has_funding-1.0")}'
        G

        bundle :install
        expect(out).to include("1 gem you depend on is looking for funding")
      end

      it "should display the fund URI if repo is updated" do
        build_git "also_has_funding" do |s|
          s.metadata = {
            "funding_uri" => "https://example.com/also_has_funding/funding",
          }
        end
        gemfile <<-G
          source "#{file_uri_for(gem_repo1)}"
          gem 'also_has_funding', :git => '#{lib_path("also_has_funding-1.0")}'
        G
        bundle :install

        build_git "also_has_funding", "1.1" do |s|
          s.metadata = {
            "funding_uri" => "https://example.com/also_has_funding/funding",
          }
        end
        gemfile <<-G
          source "#{file_uri_for(gem_repo1)}"
          gem 'also_has_funding', :git => '#{lib_path("also_has_funding-1.1")}'
        G
        bundle :install

        expect(out).to include("1 gem you depend on is looking for funding")
      end

      it "should still display the fund URI if repo is not updated" do
        build_git "also_has_funding" do |s|
          s.metadata = {
            "funding_uri" => "https://example.com/also_has_funding/funding",
          }
        end
        gemfile <<-G
          source "#{file_uri_for(gem_repo1)}"
          gem 'also_has_funding', :git => '#{lib_path("also_has_funding-1.0")}'
        G

        bundle :install
        expect(out).to include("1 gem you depend on is looking for funding")

        bundle :install
        expect(out).to include("1 gem you depend on is looking for funding")
      end
    end
  end
end
