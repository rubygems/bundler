require File.expand_path('../../spec_helper', __FILE__)

describe "gemfile install with git sources" do
  describe "when floating on master" do
    before :each do
      in_app_root

      build_git "foo"

      install_gemfile <<-G
        git "#{lib_path('foo-1.0')}"
        gem 'foo'
      G
    end

    it "fetches gems" do
      should_be_installed("foo 1.0")

      run <<-RUBY
        require 'foo'
        puts "WIN" unless defined?(FOO_PREV_REF)
      RUBY

      out.should == "WIN"
    end

    it "floats on master if no ref is specified" do
      update_git "foo"

      in_app_root2 do
        install_gemfile bundled_app2("Gemfile"), <<-G
          git "#{lib_path('foo-1.0')}"
          gem 'foo'
        G
      end

      in_app_root do
        run <<-RUBY
          require 'foo'
          puts "WIN" if defined?(FOO_PREV_REF)
        RUBY

        out.should == "WIN"
      end
    end
  end

  describe "when specifying a revision" do
    it "works" do
      in_app_root

      build_git "foo"
      @revision = revision_for(lib_path("foo-1.0"))
      update_git "foo"

      install_gemfile <<-G
        git "#{lib_path('foo-1.0')}", :ref => "#{@revision}"
        gem "foo"
      G

      run <<-RUBY
        require 'foo'
        puts "WIN" unless defined?(FOO_PREV_REF)
      RUBY

      out.should == "WIN"
    end
  end

  describe "specified inline" do
    it "installs from git even if a newer gem is available elsewhere" do
      build_git "rack", "0.8"

      install_gemfile <<-G
        source "file://#{gem_repo1}"
        gem "rack", :git => "#{lib_path('rack-0.8')}"
      G

      should_be_installed "rack 0.8"
    end
  end

  it "uses a ref if specified" do
    build_git "foo"
    @revision = revision_for(lib_path("foo-1.0"))
    update_git "foo"

    install_gemfile <<-G
      gem "foo", :git => "#{lib_path('foo-1.0')}", :ref => "#{@revision}"
    G

    run <<-RUBY
      require 'foo'
      puts "WIN" unless defined?(FOO_PREV_REF)
    RUBY

    out.should == "WIN"
  end

  it "installs from git even if a rubygems gem is present" do
    build_gem "foo", "1.0", :path => lib_path('fake_foo'), :to_system => true do |s|
      s.write "lib/foo.rb", "raise 'FAIL'"
    end

    build_git "foo", "1.0"

    install_gemfile <<-G
      gem "foo", "1.0", :git => "#{lib_path('foo-1.0')}"
    G

    should_be_installed "foo 1.0"
  end
end