require 'spec_helper'
require 'bundler/cli'

describe "bundle executable" do
  let(:source_uri) { "http://localgemserver.test" }

  context "#warn_if_root" do
    it "warns the user when install is run as root" do
      expect(Process).to receive(:uid).and_return(0)

      gemfile <<-G
        source "#{source_uri}"
      G

      warning = <<-W

WARNING ****************************************************************
Running bundler with sudo will likely have unintended consequences.
If bundler requires you to run a command with sudo it will let you know.
************************************************************************

      W

      output = capture_output {
        Bundler::CLI.new.warn_if_root
      }
      expect(output).to include(warning)
    end
  end

  it "returns non-zero exit status when passed unrecognized options" do
    bundle '--invalid_argument', :exitstatus => true
    expect(exitstatus).to_not be_zero
  end

  it "returns non-zero exit status when passed unrecognized task" do
    bundle 'unrecognized-tast', :exitstatus => true
    expect(exitstatus).to_not be_zero
  end
end
