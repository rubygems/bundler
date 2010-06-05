require "spec_helper"

describe "Resolving platform craziness" do
  describe "with semi real cases" do
    before :each do
      @index = an_awesome_index
    end

    it "resolves a simple multi platform gem" do
      dep "nokogiri"
      platforms "ruby", "java"

      should_resolve_as %w(nokogiri-1.4.2 nokogiri-1.4.2-java weakling-0.0.3)
    end

    it "doesn't pull gems when it doesn't exist for the current platform" do
      dep "nokogiri"
      platforms "ruby"

      should_resolve_as %w(nokogiri-1.4.2)
    end

    it "doesn't pulls gems when the version is available for all requested platforms" do
      dep "nokogiri"
      platforms "mswin32"

      should_resolve_as %w(nokogiri-1.4.2.1-x86-mswin32)
    end
  end

  describe "with conflicting cases" do
    before :each do
      @index = build_index do
        gem "foo", "1.0.0" do
          dep "bar", ">= 0"
        end

        gem 'bar', "1.0.0" do
          dep "baz", "~> 1.0.0"
        end

        gem "bar", "1.0.0", "java" do
          dep "baz", " ~> 1.1.0"
        end

        gem "baz", %w(1.0.0 1.1.0 1.2.0)
      end
    end

    it "does something" do
      platforms "ruby", "java"
      dep "foo"

      should_conflict_on "baz"
    end
  end
end