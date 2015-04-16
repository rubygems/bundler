require 'spec_helper'
require 'bundler/installer/parallel_installer'

describe ParallelInstaller::SpecInstallation do
  describe "#ready_to_enqueue?" do

    let!(:dep) do
      a_spec = Object.new
      def a_spec.name
        "I like tests"
      end
      a_spec
    end

    context "when in enqueued state" do
      it "is falsey" do
        spec = ParallelInstaller::SpecInstallation.new(dep)
        spec.state = :enqueued
        expect(spec.ready_to_enqueue?).to be_falsey
      end
    end

    context "when in installed state" do
      it "returns falsey" do
        spec = ParallelInstaller::SpecInstallation.new(dep)
        spec.state = :installed
        expect(spec.ready_to_enqueue?).to be_falsey
      end
    end

    it "returns truthy" do
      spec = ParallelInstaller::SpecInstallation.new(dep)
      expect(spec.ready_to_enqueue?).to be_truthy
    end
  end

end
