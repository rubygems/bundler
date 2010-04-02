require File.expand_path('../../spec_helper', __FILE__)

describe "bundle show" do
  before :each do
    install_gemfile <<-G
      source "file://#{gem_repo1}"
      gem "rails"
    G
  end

  it "prints path if gem exists in bundle" do
    bundle "show rails"
    out.should == default_bundle_path('gems', 'rails-2.3.2').to_s
  end

  it "complains if gem not in bundle" do
    bundle "show missing"
    out.should =~ /could not find gem 'missing'/i
  end

  describe "while locked" do
    before :each do
      bundle :lock
    end

    it "prints path if gem exists in bundle" do
      bundle "show rails"
      out.should == default_bundle_path('gems', 'rails-2.3.2').to_s
    end

    it "complains if gem not in bundle" do
      bundle "show missing"
      out.should =~ /could not find gem 'missing'/i
    end
  end

end

describe "bundle show with a git repo" do
  before :each do
    build_git "foo", "1.0"
    update_git "foo", :branch => "omg" do |s|
      s.write "lib/foo.rb", "FOO = '1.0.omg'"
    end
    update_git "foo" # switch back to master branch
  end

  it "prints out git info" do
    install_gemfile <<-G
      gem "foo", :git => "#{lib_path('foo-1.0')}"
    G
    should_be_installed "foo 1.0"
    bundle :show
    out.should include("foo (1.0 master-")
  end

  it "prints out branch names other than master" do
    install_gemfile <<-G
      gem "foo", :git => "#{lib_path('foo-1.0')}", :branch => "omg"
    G
    should_be_installed "foo 1.0.omg"
    bundle :show
    out.should include("foo (1.0 omg-")
  end
end