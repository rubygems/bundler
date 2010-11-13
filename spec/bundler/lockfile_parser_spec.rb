require "spec_helper"

describe Bundler::LockfileParser do
  include Bundler::GemHelpers

  let(:gemfile_string) do
    <<-G
source "file://#{gem_repo1}"

gem "rack"
    G
  end

  before { install_gemfile gemfile_string }

  subject { Bundler::LockfileParser.new(File.read(bundled_app("Gemfile.lock"))) }

  it "parses the bundler version" do
    subject.metadata["version"].should == Bundler::VERSION
  end
end
