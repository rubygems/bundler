require "spec_helper"

describe "ruby requirement" do
  # As discovered by https://github.com/bundler/bundler/issues/4147, there is
  # no test coverage to ensure that adding a gem is possible with a ruby
  # requirement. This test verifies the fix, committed in bfbad5c5.
  it "allows adding gems" do
    install_gemfile <<-G
      source "file://#{gem_repo1}"
      ruby "#{RUBY_VERSION}"
      gem "rack"
    G

    install_gemfile <<-G
      source "file://#{gem_repo1}"
      ruby "#{RUBY_VERSION}"
      gem "rack"
      gem "rack-obama"
    G

    expect(exitstatus).to eq(0) if exitstatus
    should_be_installed "rack-obama 1.0"
  end
end
