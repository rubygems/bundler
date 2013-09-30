require 'spec_helper'


describe "bundle executable" do
  it "returns non-zero exit status when passed unrecognized options" do
    bundle '--invalid_argument', :exitstatus => true
    expect(exitstatus).to_not be_zero
  end

  it "returns non-zero exit status when passed unrecognized task" do
    bundle 'unrecognized-tast', :exitstatus => true
    expect(exitstatus).to_not be_zero
  end
end
