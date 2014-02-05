# encoding: utf-8
require 'spec_helper'
require 'bundler'
require 'bundler/safe_catch'
require 'bundler/current_ruby'

class RecursiveTmpResolver
  include Bundler::SafeCatch
end

describe Bundler::SafeCatch do
  let(:resolver) { RecursiveTmpResolver.new() }

  it "should use safe_catch on jruby" do
    if Bundler.current_ruby.jruby?
      expect(Bundler::SafeCatch::Internal).to receive(:catch).and_call_original
      expect(Bundler::SafeCatch::Internal).to receive(:throw).and_call_original

      retval = resolver.safe_catch(:resolve) do
        resolver.safe_throw(:resolve, "good bye world")
      end
      expect(retval).to eq("good bye world")
    end
  end

  it "should use regular catch/throw on MRI" do
    if Bundler.current_ruby.mri?
      expect(Bundler::SafeCatch::Internal).to_not receive(:catch)
      expect(Bundler::SafeCatch::Internal).to_not receive(:throw)

      retval = resolver.safe_catch(:resolve) do
        resolver.safe_throw(:resolve, "good bye world")
      end
      expect(retval).to eq("good bye world")
    end
  end
end
