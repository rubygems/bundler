# frozen_string_literal: true
require "spec_helper"

describe "gemfile with only_platforms" do
  it "only puts the given platforms in the lockfile" do
    platforms = [local, pl("x79-foo_platform-19")]
    install_gemfile! "only_platforms(*#{platforms.map(&:to_s)})"

    expect(the_bundle.locked_gems.platforms).to eq(platforms.sort_by(&:to_s))
  end
end
