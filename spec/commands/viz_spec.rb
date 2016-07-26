# frozen_string_literal: true
require "spec_helper"

describe "bundle viz", :ruby => "1.9.3", :if => Bundler.which("dot") do
  let(:graphviz_lib) do
    graphviz_glob = base_system_gems.join("gems/ruby-graphviz*/lib")
    Dir[graphviz_glob].first
  end

  before do
    ENV["RUBYOPT"] = "-I #{graphviz_lib}"
  end

  it "graphs gems from the Gemfile" do
    install_gemfile <<-G
      source "file://#{gem_repo1}"
      gem "rack"
      gem "rack-obama"
    G

    bundle! "viz"
    expect(out).to include("gem_graph.png")

    bundle! "viz", :format => "dot"
    expect(bundled_app("gem_graph.dot")).to read_as(strip_whitespace(<<-DOT))
      digraph Gemfile {
      	graph [bb="0,0,217.82,108",
      		concentrate=true,
      		nodesep=0.55,
      		normalize=true
      	];
      	node [fontname="Arial, Helvetica, SansSerif",
      		label="\\N"
      	];
      	edge [fontname="Arial, Helvetica, SansSerif",
      		fontsize=12,
      		weight=2
      	];
      	default	 [fillcolor="#B9B9D5",
      		fontsize=16,
      		height=0.5,
      		label=default,
      		pos="32.02,90",
      		shape=box3d,
      		style=filled,
      		width=0.88943];
      	rack	 [fillcolor="#B9B9D5",
      		height=0.5,
      		label=rack,
      		pos="161.02,18",
      		style=filled,
      		width=0.75];
      	default -> rack	 [constraint=false,
      		pos="e,140.64,30.056 63.576,71.876 84.405,60.574 111.5,45.872 131.83,34.841"];
      	"rack-obama"	 [fillcolor="#B9B9D5",
      		height=0.5,
      		label="rack-obama",
      		pos="161.02,90",
      		style=filled,
      		width=1.5777];
      	default -> "rack-obama"	 [constraint=false,
      		pos="e,103.95,90 64.27,90 74.087,90 83.904,90 93.721,90"];
      	"rack-obama" -> rack	 [pos="e,161.02,36.104 161.02,71.697 161.02,63.983 161.02,54.712 161.02,46.112"];
      }
    DOT
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

    bundle! "viz"
    expect(out).to include("gem_graph.png")

    bundle! "viz", :format => :debug, :version => true
    expect(out).to eq(strip_whitespace(<<-EOS).strip)
      digraph Gemfile {
      concentrate = "true";
      normalize = "true";
      nodesep = "0.55";
      edge[ weight  =  "2"];
      node[ fontname  =  "Arial, Helvetica, SansSerif"];
      edge[ fontname  =  "Arial, Helvetica, SansSerif" , fontsize  =  "12"];
      default [style = "filled", fillcolor = "#B9B9D5", shape = "box3d", fontsize = "16", label = "default"];
      rack [style = "filled", fillcolor = "#B9B9D5", label = "rack\\n1.3.pre"];
        default -> rack [constraint = "false"];
      "rack-obama" [style = "filled", fillcolor = "#B9B9D5", label = "rack-obama\\n1.0"];
        default -> "rack-obama" [constraint = "false"];
        "rack-obama" -> rack;
      }
      debugging bundle viz...
    EOS
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

      bundle! "viz --without=rails"
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

      bundle! "viz --without=rails:rack"
      expect(out).to include("gem_graph.png")
    end
  end
end
