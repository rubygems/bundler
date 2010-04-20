require "spec_helper"

describe "Resolving" do

  before :each do
    @deps = []
    @index = an_awesome_index
  end

  it "resolves" do
    dep "rack"

    should_resolve_as [gem("rack", "1.1")]
  end
end