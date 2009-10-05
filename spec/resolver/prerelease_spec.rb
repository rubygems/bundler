require File.expand_path(File.dirname(__FILE__) + '/../spec_helper')

describe "Resolving specs with prerelease dependencies" do
  def resolving(deps)
    Bundler::Resolver.resolve(deps, [@index])
  end

  it "does not include prereleases by default" do
    @index = build_index do
      add_spec "bar", "3.0.pre"
      add_spec "bar", "2.0"
    end

    deps = [build_dep("bar", ">= 2.0")]
    resolving(deps).should match_gems "bar" => ["2.0"]
  end

  it "supports a single prerelease dependency" do
    @index = build_index do
      add_spec "bar", "2.0.0.rc2"
    end

    deps = [build_dep("bar", ">= 2.0.0.rc1")]

    resolving(deps).should match_gems "bar" => ["2.0.0.rc2"]
  end

  it "child dependencies can require prerelease gems" do
    @index = build_index do
      add_spec "foo", "2.0" do
        runtime "bar", ">= 3.0.pre"
      end
      add_spec "foo", "1.5" do
        runtime "bar", ">= 2.0"
      end
      add_spec "bar", "3.0.pre"
      add_spec "bar", "2.5"
      add_spec "bar", "2.0"
    end

    deps = [build_dep("foo")]
    resolving(deps).should match_gems "foo" => ["2.0"], "bar" => ["3.0.pre"]
  end

  it "doesn't blow up if there are only prerelease versions for a gem" do
    @index = build_index do
      add_spec "first", "1.0" do
        runtime "second", ">= 0"
      end
      add_spec "second", "1.0.pre"
    end

    deps = [build_dep("first"), build_dep("second", "=1.0.pre")]
    resolving(deps).should match_gems("first" => ["1.0"], "second" => ["1.0.pre"])
  end

  it "does backtracking" do
    @index = build_index do
      add_spec "first", "1.0" do
        runtime "second", ">= 1.0"
      end
      add_spec "second", "1.0" do
        runtime "third", ">= 1.0"
      end
      add_spec "third", "1.0"
      add_spec "third", "2.0.pre"
    end

    deps = [build_dep("first"), build_dep("third", ">= 2.0.pre")]
    resolving(deps).should match_gems("first" => ["1.0"], "second" => ["1.0"], "third" => ["2.0.pre"])
  end

  it "resolves well" do
    @index = build_index do
      add_spec "first", "1.0" do
        runtime "second", ">= 1.0"
        runtime "third", ">= 1.0"
      end
      add_spec "second", "1.0" do
        runtime "fourth", ">= 1.0"
      end
      add_spec "third", "1.0" do
        runtime "fourth", ">= 2.0.pre"
      end
      add_spec "fourth", "1.0"
      add_spec "fourth", "2.0.pre"
    end

    deps = [build_dep("first")]
    resolving(deps).should match_gems(
      "first"  => ["1.0"],
      "second" => ["1.0"],
      "third"  => ["1.0"],
      "fourth" => ["2.0.pre"]
    )
  end

  it "is smart" do
    @index = build_index do
      add_spec "first", "1.0" do
        runtime "second", ">= 1.0.pre"
      end
      add_spec "second", "1.0.pre" do
        runtime "third", ">= 1.0"
      end
      add_spec "third", "1.0"
      add_spec "third", "2.0.pre"
    end

    deps = [build_dep("first", "1.0")]
    resolving(deps).should match_gems("first" => ["1.0"], "second" => ["1.0.pre"], "third" => ["1.0"])
  end
end