require 'spec_helper'

describe "real world edgecases", :realworld => true do
  # there is no rbx-relative-require gem that will install on 1.9
  it "ignores extra gems with bad platforms", :ruby => "1.9" do
    install_gemfile <<-G
      source :rubygems
      gem "linecache", "0.46"
    G
    err.should eq("")
  end

  # https://github.com/carlhuda/bundler/issues/1202
  it "bundle cache works with rubygems 1.3.7 and pre gems" do
    install_gemfile <<-G
      source :rubygems
      gem "rack", "1.3.0.beta2"
    G
    bundle :cache
    out.should_not include("Removing outdated .gem files from vendor/cache")
  end
end
