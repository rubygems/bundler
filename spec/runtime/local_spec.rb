require "spec_helper"

describe "Bundler.setup with local-override" do
  before do
    @path = bundled_app(File.join('vendor', 'rack'))

    build_lib "rack", "1.1", :path => @path do |s|
      s.write "lib/rack.rb", "puts 'LOCAL'"
    end
  end

  describe "on top of a git source" do
    before do
      build_git "rack", "1.1" do |s|
        s.write "lib/rack.rb", "puts 'GIT'"
      end

      install_gemfile <<-G
        gem 'rack', :git => "#{lib_path('rack-1.1')}", :local => "#{@path}"
      G
    end

    it "prefers the path specificed in local" do
      run "require 'rack'"
      out.should == "LOCAL"
    end

    describe "when the path is missing" do
      it "quietly falls back" do
        FileUtils.rm_rf(@path)
        run "require 'rack'"
        out.should == "GIT"
      end
    end
  end

  describe "on top of a rubygems source" do
    before do
      install_gemfile <<-G
        source "file://#{gem_repo1}"
        gem 'rack', :local => "#{@path}"
      G
    end

    it "prefers the path specificed in local" do
      run "require 'rack'"
      out.should == "LOCAL"
    end
  end
end
