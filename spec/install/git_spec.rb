require File.expand_path('../../spec_helper', __FILE__)

describe "bbl install with git sources" do
  before :each do
    in_app_root
  end

  it "fetches gems" do
    build_git "foo"

    install_gemfile <<-G
      git "#{lib_path('foo-1.0')}"
      gem 'foo'
    G
    
    should_be_installed("foo 1.0")
  end
end