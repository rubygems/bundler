# frozen_string_literal: true

RSpec.describe Bundler::Gemfile do
  before do
    install_gemfile <<-G
      source "file://#{gem_repo1}"
      gem "weakling", "~> 0.0.1"
      gem "rack-test", :group => [:test]
      gem "rack", :group => [:prod, :dev]
      gem "rspec", :group => [:test]
    G
  end

  context "#gem_contents" do
    it "with show_groups true" do
      definition = Bundler.definition
      contents = subject.gem_contents(definition.dependencies.find {|d| d.name == "rack" }, true)
      expect(contents.join).to eq("gem \"rack\", :groups => [:prod, :dev]")
    end

    it "with show_groups false" do
      definition = Bundler.definition
      contents = subject.gem_contents(definition.dependencies.find {|d| d.name == "rack" }, false)
      expect(contents.join).to eq("gem \"rack\"")
    end
  end

  context "#groups_wise" do
    it "returns group wise gems" do
      definition = Bundler.definition
      a = definition.dependencies.group_by(&:groups).each_key(&:sort!).sort_by(&:first)
      expected = <<-E
      group :test do
        gem "rack-test"
        gem "rspec"
      end
      E
      expect(subject.groups_wise(a[2][1], a[2][0]).join("\n").gsub(/\n{3,}/, "\n\n")).to eq(strip_whitespace(expected))
    end
  end
end
