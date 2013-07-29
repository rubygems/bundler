require "spec_helper"

describe "bundle command names" do
  it "work when given fully" do
    bundle "install"
    expect(err).to eq("")
    expect(out).to match(/Bundler::GemfileNotFound/)
  end

  it "work when not ambiguous" do
    bundle "ins"
    expect(err).to eq("")
    expect(out).to match(/Bundler::GemfileNotFound/)
  end

  it "print a friendly error when ambiguous" do
    bundle "i"
    expect(err).to eq("")
    expect(out).to match(/Ambiguous command i matches \[init, inject, install\]/)
  end
end
