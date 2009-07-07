require File.join(File.dirname(__FILE__), "spec_helper")

describe "Finder" do
  before(:all) do
    index = build_index do
      add_spec "activemerchant", "1.4.1" do
        runtime "activesupport", ">= 1.4.1"
      end
      add_spec "activesupport", "3.0.0"
      add_spec "activesupport", "2.3.2"
      add_spec "action_pack", "2.3.2" do
        runtime "activesupport", "= 2.3.2"
      end
    end

    @faster = Bundler::Finder.new.append(index, "http://foo")
  end

  def only_have_specs(*names)
    simple_matcher("only have spec") do |given, matcher|
      given_names = given.map{ |s| s.full_name }
      matcher.failure_message = "expected specs to only contain #{names.inspect} but got: #{given_names.inspect}"
      names.sort == given_names.sort
    end
  end

  alias only_have_spec only_have_specs

  it "find the gem given correct search" do
    [
      build_dep("activemerchant", "= 1.4.1"),
      build_dep("activemerchant", ">= 1.4.1"),
      build_dep("activemerchant", "<= 1.4.1"),
      build_dep("activemerchant", ">= 1.4.0"),
      build_dep("activemerchant", ">= 1.4"),
      build_dep("activemerchant", ">= 1.3.0"),
      build_dep("activemerchant", ">= 1.3"),
      build_dep("activemerchant", ">= 1"),
      build_dep("activemerchant", ">= 1.4.1"),
      build_dep("activemerchant", "> 0"),
      build_dep("activemerchant", "<= 1.4.1"),
      build_dep("activemerchant", "<= 2"),
    ].each { |dep| @faster.search(dep).should only_have_spec("activemerchant-1.4.1") }
  end

  it "does not find the gem given an incorrect search" do
    [
      build_dep("activemerchant", "= 1.4.0"),
      build_dep("activemerchant", "= 1.4"),
      build_dep("activemerchant", "= 1"),
      build_dep("activemerchant", ">= 1.4.2"),
      build_dep("activemerchant", "> 1.4.1"),
      build_dep("activemerchant", "<= 1.4.0"),
      build_dep("activemerchant", "< 1.4.1"),
    ].each { |dep| @faster.search(dep).should be_empty }
  end

  it "returns all gem specs that match the search" do
    @faster.search(build_dep("activesupport", "> 0")).should only_have_specs("activesupport-2.3.2", "activesupport-3.0.0")
  end
end