# frozen_string_literal: true

require "bundler/diff"

RSpec.describe Bundler::Diff do
  let(:current_lockfile) { "thor (0.20.0)\n" }
  let(:final_lockfile) { "thor (0.20.0)\nrack(1.9.0)\n" }
  let(:diff)	{ described_class.new(current_lockfile, final_lockfile) }

  it "should print diff of two strings" do
    output = diff.to_s
    expect(output).to include "+rack(1.9.0)\n"
  end
end
