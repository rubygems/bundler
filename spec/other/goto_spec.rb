require 'spec_helper'

describe "bundle goto" do

  before :each do
    install_gemfile <<-G
      source "file://#{gem_repo1}"
      gem "rails"
      gem "rack"
    G
  end

  it "opens the homepage using the BROWSER env variable" do
    bundle "goto rack", :env => { "BROWSER" => "echo open" }
    expect(out).to eq("open http://rack.github.io/")
  end

  it "complains if no BROWSER is set" do
    bundle "goto rack", :env => { "BROWSER" => "" }
    expect(out).to match(/To visit the gem's homepage, set the \$BROWSER/)
  end

  it "prints an error if the gemspec doesn't contain homepage" do
    bundle "goto rails"
    expect(out).to eq("No homepage available for this gem")
  end

end
