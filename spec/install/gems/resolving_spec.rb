require File.expand_path('../../../spec_helper', __FILE__)

describe "bundle install with gem sources" do
  describe "install time dependencies" do
    it "installs gems with implicit rake dependencies" do
      install_gemfile <<-G
        source "file://#{gem_repo1}"
        gem "with_implicit_rake_dep"
        gem "another_implicit_rake_dep"
        gem "rake"
      G

      run <<-R
        require 'implicit_rake_dep'
        require 'another_implicit_rake_dep'
        puts IMPLICIT_RAKE_DEP
        puts ANOTHER_IMPLICIT_RAKE_DEP
      R
      out.should == "YES\nYES"
    end

    it "works with crazy rubygem plugin stuff" do
      install_gemfile <<-G
        source "file://#{gem_repo1}"
        gem "net_c"
        gem "net_e"
      G

      should_be_installed "net_a 1.0", "net_b 1.0", "net_c 1.0", "net_d 1.0", "net_e 1.0"
    end
  end
end