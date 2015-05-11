require "spec_helper"

describe "bundle viz" do
  before :each do
    `gem install ruby-graphviz`
  end

  context "with a standard Gemfile" do
    before :each do
      `gem install httpi -v "= 2.2.7"` # requires any rack
      `gem install rack -v "= 1.1.1"`
      # TODO: this whole approach is bad

      install_gemfile <<-G
        source "file://#{system_gem_path}"
        gem "httpi", "= 2.2.7"
        gem "rack", "= 1.1.1"
      G
    end

    it "correctly generates a graph" do
      bundle "viz"

      expect(out).to include("gem_graph.png")
    end
  end

  context "with a Gemfile that has a prerelease as a satisfying dependency" do
    before :each do
      `gem install httpi -v "= 2.2.7"` # requires any rack
      `gem install rack -v "= 1.1.1.pre"`

      install_gemfile <<-G
        source "file://#{system_gem_path}"
        gem "httpi", "= 2.2.7"
        gem "rack", "= 1.1.1.pre"
      G
    end

    it "correctly generates a graph" do
      bundle "viz"

      expect(out).to include("gem_graph.png")
    end
  end
end
