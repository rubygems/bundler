require 'spec_helper'

describe "bundle command names" do
  it "work when given fully"

  it "work when not ambiguous"

  it "print a friendly error when ambiguous" do
    bundle "i"
    expect(out).to match(/helpful message/)
    expect(err).to eq("")
  end
end
