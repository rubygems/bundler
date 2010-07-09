require "spec_helper"

describe "Running bin/* commands" do
  it "runs the bundled command when in the bundle" do
    install_gemfile <<-G
      source "file://#{gem_repo1}"
      gem "rack"
    G

    build_gem "rack", "2.0", :to_system => true do |s|
      s.executables = "rackup"
    end

    gembin "rackup"
    out.should == "1.0.0"
  end

  it "runs the bundled command when out of the bundle" do
    install_gemfile <<-G
      source "file://#{gem_repo1}"
      gem "rack"
    G

    build_gem "rack", "2.0", :to_system => true do |s|
      s.executables = "rackup"
    end

    Dir.chdir(tmp) do
      gembin "rackup"
      out.should == "1.0.0"
    end
  end

  it "works with gems in path" do
    build_lib "rack", :path => lib_path("rack") do |s|
      s.executables = 'rackup'
    end

    install_gemfile <<-G
      gem "rack", :path => "#{lib_path('rack')}"
    G

    build_gem 'rack', '2.0', :to_system => true do |s|
      s.executables = 'rackup'
    end

    gembin "rackup"
    out.should == '1.0'
  end

  it "don't bundle da bundla" do
    build_gem "bundler", Bundler::VERSION, :to_system => true do |s|
      s.executables = "bundle"
    end

    install_gemfile <<-G
      source "file://#{gem_repo1}"
      gem "bundler"
    G

    bundled_app("bin/bundle").should_not exist
  end
end