require "spec_helper"

describe "Resolving" do

  before :each do
    @index = an_awesome_index
  end

  it "resolves a single gem" do
    dep "rack"

    should_resolve_as %w(rack-1.1)
  end

  it "resolves a gem with dependencies" do
    dep "actionpack"

    should_resolve_as %w(actionpack-2.3.5 activesupport-2.3.5 rack-1.0)
  end
end