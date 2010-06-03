require "spec_helper"

describe "Resolving platform craziness" do
  describe "with semi real cases" do
    before :each do
      @index = an_awesome_index
    end

    it "resolves a simple multi platform gem" do
      dep "nokogiri"
      platforms "ruby", "java"

      should_resolve_as %w(nokogiri-1.4.2.1 nokogiri-1.4.2.1-java weakling-0.0.3)
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