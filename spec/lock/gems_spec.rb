require "spec_helper"

describe "bundle lock with gems" do
  before :each do
    system_gems "rack-0.9.1"
    gemfile <<-G
      source "file://#{gem_repo1}"
      gem "rack"
    G
  end

  it "correctly serializes GemCache sources" do
    pending "GemCache needs a #to_lock method"
    gemfile <<-G
      source Bundler::Source::GemCache.new("path" => "#{tmp}")
    G

    bundle :lock
    err.should be_empty
  end
end
