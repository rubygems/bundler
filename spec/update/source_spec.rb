require "spec_helper"

describe "bundle update" do
  describe "git sources" do
    before :each do
      build_repo2
      @git = build_git "foo", :path => lib_path("foo") do |s|
        s.executables = "foobar"
      end
    end

    context 'without remote repo' do
      before :each do
        install_gemfile <<-G
          source "file://#{gem_repo2}"
          git "#{lib_path('foo')}" do
            gem 'foo'
          end
          gem 'rack'
        G
      end

      it "updates the source" do
        update_git "foo", :path => @git.path

        bundle "update --source foo"

        in_app_root do
          run <<-RUBY
            require 'foo'
            puts "WIN" if defined?(FOO_PREV_REF)
          RUBY

          out.should == "WIN"
        end
      end

      it "unlocks gems that were originally pulled in by the source" do
        update_git "foo", "2.0", :path => @git.path

        bundle "update --source foo"
        should_be_installed "foo 2.0"
      end

      it "leaves all other gems frozen" do
        update_repo2
        update_git "foo", :path => @git.path

        bundle "update --source foo"
        should_be_installed "rack 1.0"
      end
    end

    context 'with remote repo' do

      it 'should update with tag option' do
        bare_mock_remote_git = build_bare_git lib_path("remote")
        remote_name = 'bar'

        update_git "foo", :path => @git.path,
          :remote => {:cmd => 'add', :name => remote_name, :args => "file://#{bare_mock_remote_git.path}"}

        update_git "foo", :path => @git.path,
          :remote => {:cmd => 'push', :name => remote_name}

        install_gemfile <<-G
          source "file://#{gem_repo2}"
          gem 'foo', :git => "#{lib_path('remote')}"
          gem 'rack'
        G

        update_git "foo", :path => @git.path, :branch => "bas"
        update_git "foo", :path => @git.path, :remote => {:cmd => 'push', :name => remote_name, :ref => 'bas'}
        update_git "foo", :path => @git.path, :tag => "fubar"
        update_git "foo", :path => @git.path, :remote => {:cmd => 'push', :name => remote_name, :ref => 'fubar'}
        update_git "foo", :path => @git.path, :remote => {:cmd => 'push', :name => remote_name, :ref => ':bas'}

        gemfile <<-G
          source "file://#{gem_repo2}"
          gem 'foo', :git => "#{lib_path('remote')}", :tag => "fubar"
          gem 'rack'
        G

        bundle("update", :exitstatus => true)
        exitstatus.should == 0
      end

    end
  end
end
