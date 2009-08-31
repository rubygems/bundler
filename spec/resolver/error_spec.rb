require File.expand_path(File.dirname(__FILE__) + '/../spec_helper')

describe "Bundler error reporting" do

  it "reports an error when a root level dependency is not found in the index" do
    index = build_index do
      add_spec "bar", "2.0.0"
    end

    deps = [build_dep("foo")]
    lambda { Bundler::Resolver.resolve(deps, [index]) }.should raise_error(Bundler::GemNotFound)
  end

  it "outputs a warning if a child dependency is not found but the dependency graph can be resolved" do
    index = build_index do
      add_spec "foo", "1.0" do
        runtime "missing", ">= 0"
      end
      add_spec "foo", "0.5" do
        runtime "present", ">= 0"
      end
      add_spec "present", "1.0"
    end

    deps = [build_dep("foo")]
    Bundler::Resolver.resolve(deps, [index]).should_not be_nil
    @log_output.should have_log_message("Could not find gem 'missing (>= 0, runtime)' (required by 'foo (>= 0, runtime)') in any of the sources")
  end

  it "reports a helpful error when a VersionConflict is encountered" do
    index = build_index do
      add_spec "rails", "2.0" do
        runtime "actionpack", "= 2.0"
      end
      add_spec "actionpack", "2.0" do
        runtime "activesupport", "= 2.0"
      end
      add_spec "activesupport", "2.0"
      add_spec "activesupport", "1.5"
      add_spec "activemerchant", "1.5" do
        runtime "activesupport", "= 1.5"
      end
    end

    deps = [build_dep("rails"), build_dep("activemerchant")]

    lambda { Bundler::Resolver.resolve(deps, [index]) }.
      should raise_error(Bundler::VersionConflict, /No compatible versions could be found for required dependencies/)
  end
end
