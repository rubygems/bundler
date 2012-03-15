require "spec_helper"

describe "bundle install with maven" do
  it "fetches gems" do
    build_lib "foo"

    install_gemfile <<-G
      mvn "default"
      gem 'mvn:commons-lang:commons-lang','2.3'
    G

    should_be_installed("foo 1.0")
  end
  
end
