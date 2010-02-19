require File.expand_path('../../spec_helper', __FILE__)

describe "bundle exec" do
  before :each do
    system_gems "rack-1.0.0", "rack-0.9.1"
  end

  it "activates the correct gem" do
    gemfile <<-G
      gem "rack", "0.9.1"
    G

    bundle "exec rackup"
    out.should == "0.9.1"
  end

  it "works when the bins are in ~/.bundle" do
    install_gemfile <<-G
      gem "rack"
    G

    bundle "exec rackup"
    out.should == "1.0.0"
  end

  it "works when running from a random directory" do
    install_gemfile <<-G
      gem "rack"
    G

    bundle "exec cd #{tmp('gems')} && rackup"

    out.should == "1.0.0"
  end

  it "handles different versions in different bundles" do
    build_repo2 do
      build_gem "rack_two", "1.0.0" do |s|
        s.executables = "rackup"
      end
    end

    install_gemfile <<-G
      source "file://#{gem_repo1}"
      gem "rack", "0.9.1"
    G

    Dir.chdir bundled_app2 do
      install_gemfile bundled_app2('Gemfile'), <<-G
        source "file://#{gem_repo2}"
        gem "rack_two", "1.0.0"
      G
    end

    bundle "exec rackup"

    out.should == "0.9.1"

    Dir.chdir bundled_app2 do
      bundle "exec rackup"
      out.should == "1.0.0"
    end
  end
end