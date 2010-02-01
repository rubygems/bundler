require File.expand_path('../../spec_helper', __FILE__)

describe "Bundler.setup" do
  describe "with paths" do
    it "activates the gems in the path source" do
      pending
      system_gems "rack-1.0.0"

      build_lib "rack", "1.0.0" do |s|
        s.write "lib/rack.rb", "puts 'WIN'"
      end

      gemfile <<-G
        path "#{lib_path('rack-1.0.0')}"
        source "file://#{gem_repo1}"
        gem "rack"
      G

      run "require 'rack'"
      out.should == "WIN"
    end
  end
end