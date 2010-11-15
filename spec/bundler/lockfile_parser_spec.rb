require "spec_helper"

describe Bundler::LockfileParser do
  include Bundler::GemHelpers

  before do
    install_gemfile <<-G
      source "file://#{gem_repo1}"
      gem "rack"
    G
  end

  subject do
    lockfile_contents = File.read(bundled_app("Gemfile.lock"))
    Bundler::LockfileParser.new(lockfile_contents)
  end

  it "parses the bundler version" do
    subject.metadata["version"].should == Bundler::VERSION
  end
end
