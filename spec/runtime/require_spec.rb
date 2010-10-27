require "spec_helper"

describe "Bundler.require" do
  before :each do
    build_lib "one", "1.0.0" do |s|
      s.write "lib/baz.rb", "puts 'baz'"
      s.write "lib/qux.rb", "puts 'qux'"
    end

    build_lib "two", "1.0.0" do |s|
      s.write "lib/two.rb", "puts 'two'"
      s.add_dependency "three", "= 1.0.0"
    end

    build_lib "three", "1.0.0" do |s|
      s.write "lib/three.rb", "puts 'three'"
      s.add_dependency "seven", "= 1.0.0"
    end

    build_lib "four", "1.0.0" do |s|
      s.write "lib/four.rb", "puts 'four'"
    end

    build_lib "five", "1.0.0", :no_default => true do |s|
      s.write "lib/mofive.rb", "puts 'five'"
    end

    build_lib "six", "1.0.0" do |s|
      s.write "lib/six.rb", "puts 'six'"
    end

    build_lib "seven", "1.0.0" do |s|
      s.write "lib/seven.rb", "puts 'seven'"
    end

    gemfile <<-G
      path "#{lib_path}"
      gem "one", :group => :bar, :require => %w(baz qux)
      gem "two"
      gem "three", :group => :not
      gem "four", :require => false
      gem "five"
      gem "six", :group => "string"
      gem "seven", :group => :not
    G
  end

  it "requires the gems" do
    # default group
    run "Bundler.require"
    check out.should == "two"

    # specific group
    run "Bundler.require(:bar)"
    check out.should == "baz\nqux"

    # default and specific group
    run "Bundler.require(:default, :bar)"
    check out.should == "baz\nqux\ntwo"

    # specific group given as a string
    run "Bundler.require('bar')"
    check out.should == "baz\nqux"

    # specific group declared as a string
    run "Bundler.require(:string)"
    check out.should == "six"

    # required in resolver order instead of gemfile order
    run("Bundler.require(:not)")
    out.split("\n").sort.should == ['seven', 'three']
  end

  it "allows requiring gems with non standard names explicitly" do
    run "Bundler.require ; require 'mofive'"
    out.should == "two\nfive"
  end

  it "raises an exception if a require is specified but the file does not exist" do
    gemfile <<-G
      path "#{lib_path}"
      gem "two", :require => 'fail'
    G

    run <<-R
      begin
        Bundler.require
      rescue LoadError => e
        puts e.message
      end
    R
    out.should == 'no such file to load -- fail'
  end

  describe "using bundle exec" do
    it "requires the locked gems" do
      bundle "exec ruby -e 'Bundler.require'"
      check out.should == "two"

      bundle "exec ruby -e 'Bundler.require(:bar)'"
      check out.should == "baz\nqux"

      bundle "exec ruby -e 'Bundler.require(:default, :bar)'"
      out.should == "baz\nqux\ntwo"
    end
  end

  describe "order" do
    before(:each) do
      build_lib "one", "1.0.0" do |s|
        s.write "lib/one.rb", <<-ONE
          if defined?(Two)
            Two.two
          else
            puts "two_not_loaded"
          end
          puts 'one'
        ONE
      end

      build_lib "two", "1.0.0" do |s|
        s.write "lib/two.rb", <<-TWO
          module Two
            def self.two
              puts 'module_two'
            end
          end
          puts 'two'
        TWO
      end
    end

    it "works when the gems are in the Gemfile in the correct order" do
      gemfile <<-G
        path "#{lib_path}"
        gem "two"
        gem "one"
      G

      run "Bundler.require"
      check out.should == "two\nmodule_two\none"
    end

    describe "a gem with different requires for different envs" do
      before(:each) do
        build_gem "multi_gem", :to_system => true do |s|
          s.write "lib/one.rb", "puts 'ONE'"
          s.write "lib/two.rb", "puts 'TWO'"
        end

        install_gemfile <<-G
          gem "multi_gem", :require => "one", :group => :one
          gem "multi_gem", :require => "two", :group => :two
        G
      end

      it "requires both with Bundler.require(both)" do
        run "Bundler.require(:one, :two)"
        out.should == "ONE\nTWO"
      end

      it "requires one with Bundler.require(:one)" do
        run "Bundler.require(:one)"
        out.should == "ONE"
      end

      it "requires :two with Bundler.require(:two)" do
        run "Bundler.require(:two)"
        out.should == "TWO"
      end
    end

    it "fails when the gems are in the Gemfile in the wrong order" do
      gemfile <<-G
        path "#{lib_path}"
        gem "one"
        gem "two"
      G

      run "Bundler.require"
      check out.should == "two_not_loaded\none\ntwo"
    end

    describe "with busted gems" do
      it "should be busted" do
        build_gem "busted_require", :to_system => true do |s|
          s.write "lib/busted_require.rb", "require 'no_such_file_omg'"
        end

        install_gemfile <<-G
          gem "busted_require"
        G

        run "Bundler.require", :expect_err => true
        err.should include("no such file to load -- no_such_file_omg")
      end
    end
  end
end

describe "Bundler.require with platform specific dependencies" do
  it "does not require the gems that are pinned to other platforms" do
    install_gemfile <<-G
      source "file://#{gem_repo1}"

      platforms :#{not_local_tag} do
        gem "fail", :require => "omgomg"
      end

      gem "rack", "1.0.0"
    G

    run "Bundler.require", :expect_err => true
    err.should be_empty
  end

  it "requires gems pinned to multiple platforms, including the current one" do
    install_gemfile <<-G
      source "file://#{gem_repo1}"

      platforms :#{not_local_tag}, :#{local_tag} do
        gem "rack", :require => "rack"
      end
    G

    run "Bundler.require; puts RACK", :expect_err => true

    check out.should == "1.0.0"
    err.should be_empty
  end
end
