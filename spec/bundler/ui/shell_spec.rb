require 'spec_helper'
require 'bundler/vendored_thor'

describe Bundler::UI::Shell do
  let(:shell) { Bundler::UI::Shell.new }

  before do
    shell.level = "debug"
  end

  %w(info confirm warn debug).each do |method_name|
    describe "##{method_name}" do
      it "outputs to STDOUT" do
        expect {
          shell.send(method_name, "Boom")
        }.to output(/Boom/).to_stdout
      end
    end
  end

  describe "#error" do
    it "outputs to STDERR" do
      expect {
        shell.error("Boom")
      }.to output(/Boom/).to_stderr
    end
  end
end
