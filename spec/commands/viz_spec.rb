# frozen_string_literal: true
require "spec_helper"

describe "bundle viz", :ruby => "1.9.3", :if => Bundler.which("dot") do
  let(:graphviz_lib) do
    graphviz_glob = base_system_gems.join("gems/ruby-graphviz*/lib")
    Dir[graphviz_glob].first
  end

  it "graphs gems from the Gemfile" do
    install_gemfile <<-G
      source "file://#{gem_repo1}"
      gem "rack"
      gem "rack-obama"
    G

    bundle "viz", :env => { "RUBYOPT" => "-I #{graphviz_lib}" }
    expect(out).to include("gem_graph.png")
  end

  it "graphs gems that are prereleases" do
    build_repo2 do
      build_gem "rack", "1.3.pre"
    end

    install_gemfile <<-G
      source "file://#{gem_repo2}"
      gem "rack", "= 1.3.pre"
      gem "rack-obama"
    G

    bundle "viz", :env => { "RUBYOPT" => "-I #{graphviz_lib}" }
    expect(out).to include("gem_graph.png")
  end

  context "--without option" do
    it "one group" do
      install_gemfile <<-G
        source "file://#{gem_repo1}"
        gem "activesupport"

        group :rails do
          gem "rails"
        end
      G

      bundle "viz --without=rails", :env => { "RUBYOPT" => "-I #{graphviz_lib}" }
      expect(out).to include("gem_graph.png")
    end

    it "two groups" do
      install_gemfile <<-G
        source "file://#{gem_repo1}"
        gem "activesupport"

        group :rack do
          gem "rack"
        end

        group :rails do
          gem "rails"
        end
      G

      bundle "viz --without=rails:rack", :env => { "RUBYOPT" => "-I #{graphviz_lib}" }
      expect(out).to include("gem_graph.png")
    end
  end
end
