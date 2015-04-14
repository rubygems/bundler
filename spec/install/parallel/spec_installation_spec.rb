require 'spec_helper'
require 'bundler/installer/parallel_installer'

describe ParallelInstaller::SpecInstallation do
  describe "#ready_to_enqueue?" do
    context "when in enqueued state" do
      it "is falsey" do
        spec = ParallelInstaller::SpecInstallation.new
        spec.state = :enqueued
        expect(spec.ready_to_enqueue?).to be_falsey
      end
    end

    context "when in installed state" do
      it "returns falsey" do
        spec = ParallelInstaller::SpecInstallation.new
        spec.state = :installed
        expect(spec.ready_to_enqueue?).to be_falsey
      end
    end

    it "returns truthy" do
      spec = ParallelInstaller::SpecInstallation.new
      expect(spec.ready_to_enqueue?).to be_truthy
    end
  end

end
