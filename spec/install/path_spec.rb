require File.expand_path('../../spec_helper', __FILE__)

describe "gemfile install with git sources" do
  before :each do
    in_app_root
  end

  it "fetches gems" do
    build_lib "foo"

    install_gemfile <<-G
      path "#{lib_path('foo-1.0')}"
      gem 'foo'
    G
    
    should_be_installed("foo 1.0")
  end
end