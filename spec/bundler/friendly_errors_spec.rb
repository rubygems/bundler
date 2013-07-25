require "spec_helper"

describe "friendly errors" do
  it "rescues ArgumentErrors" do
    expect{ Bundler.with_friendly_errors {
      raise ArgumentError.new("Ambiguous task") } }.not_to raise_error
  end

  it "rescues ArgumentErrors" do
    bundle :i
    expect(err).to be_empty
  end

  it "prints a friendly error message" do
    bundle :i
    expect(out).to match /A more helpful message/
  end
end
