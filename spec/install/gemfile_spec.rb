require "spec_helper"

describe "bundle install with Gemfile" do

  it "will display a warning if a gem is duplicated" do
    install_gemfile <<-G
      gem 'rails', '~> 4.0.0'
      gem 'rails', '~> 4.0.0'
    G
    expect(out).to include("more than once")
  end

end