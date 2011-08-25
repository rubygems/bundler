require "spec_helper"
require 'bundler/gem_helper'

describe "Bundler::GemHelper tasks" do
  context "determining gemspec" do
    it "interpolates the name when there is only one gemspec" do
      bundle 'gem test'
      app = bundled_app("test")
      helper = Bundler::GemHelper.new(app.to_s)
      helper.gemspec.name.should == 'test'
    end

    it "interpolates the name for a hidden gemspec" do
      bundle 'gem test'
      app = bundled_app("test")
      FileUtils.mv app.join('test.gemspec'), app.join('.gemspec')
      helper = Bundler::GemHelper.new(app.to_s)
      helper.gemspec.name.should == 'test'
    end

    it "should fail when there is no gemspec" do
      bundle 'gem test'
      app = bundled_app("test")
      FileUtils.rm(File.join(app.to_s, 'test.gemspec'))
      proc { Bundler::GemHelper.new(app.to_s) }.should raise_error(/Unable to determine name/)
    end

    it "should fail when there are two gemspecs and the name isn't specified" do
      bundle 'gem test'
      app = bundled_app("test")
      File.open(File.join(app.to_s, 'test2.gemspec'), 'w') {|f| f << ''}
      proc { Bundler::GemHelper.new(app.to_s) }.should raise_error(/Unable to determine name/)
    end
  end

  context "version management" do

    def version_rb
      File.join(@app.to_s, 'lib', 'test', 'version.rb')
    end

    def version_file_should_match version_string
      version_regex = Regexp.escape(version_string)

      version_file = File.readlines version_rb

      version_lines = version_file.grep(/VERSION/)
      version_lines.size.should == 1
      version_lines.first.should match version_regex
    end

    before :each do
      bundle 'gem test'
      @app = bundled_app 'test'
      @helper = Bundler::GemHelper.new(@app.to_s)
    end

    it "increases the patch by one" do
      @helper.bump :patch
      version_file_should_match "0.0.2"
    end

    it "increases the patch by one" do
      @helper.bump :minor
      version_file_should_match "0.1.0"
    end

    it "increases the major by one" do
      @helper.bump :major
      version_file_should_match "1.0.0"
    end

    it "writes whatever version you want" do
      @helper.change_version_to "3.5.8"
      version_file_should_match "3.5.8"
    end

    it "only changes the version number in the version file" do
      original_file = File.readlines(version_rb)
      original_file.map! { |x| x[/VERSION/] ? "  VERSION = \"0.0.1\" #I am a comment\n" : x}
      File.open(version_rb, 'w') { |f|f << original_file.join}

      @helper.change_version_to "1.2.3"
      new_file = File.readlines(version_rb)

      original_file_diff = original_file - new_file
      new_file_diff = new_file - original_file
      original_file_diff.size.should == 1
      new_file_diff.size.should == 1
      new_file_diff.first.should == "  VERSION = \"1.2.3\" #I am a comment\n"
    end

  end

  context "gem management" do
    def mock_confirm_message(message)
      Bundler.ui.should_receive(:confirm).with(message)
    end

    def mock_build_message
      mock_confirm_message "test 0.0.1 built to pkg/test-0.0.1.gem"
    end

    before(:each) do
      bundle 'gem test'
      @app = bundled_app("test")
      @gemspec = File.read("#{@app.to_s}/test.gemspec")
      File.open("#{@app.to_s}/test.gemspec", 'w'){|f| f << @gemspec.gsub('TODO: ', '') }
      @helper = Bundler::GemHelper.new(@app.to_s)
    end

    it "uses a shell UI for output" do
      Bundler.ui.should be_a(Bundler::UI::Shell)
    end

    describe 'build' do
      it "builds" do
        mock_build_message
        @helper.build_gem
        bundled_app('test/pkg/test-0.0.1.gem').should exist
      end

      it "raises an appropriate error when the build fails" do
        # break the gemspec by adding back the TODOs...
        File.open("#{@app.to_s}/test.gemspec", 'w'){|f| f << @gemspec }
        proc { @helper.build_gem }.should raise_error(/TODO/)
      end
    end

    describe 'install' do
      it "installs" do
        mock_build_message
        mock_confirm_message "test (0.0.1) installed"
        @helper.install_gem
        bundled_app('test/pkg/test-0.0.1.gem').should exist
        %x{gem list}.should include("test (0.0.1)")
      end

      it "raises an appropriate error when the install fails" do
        @helper.should_receive(:build_gem) do
          # write an invalid gem file, so we can simulate install failure...
          FileUtils.mkdir_p(File.join(@app.to_s, 'pkg'))
          path = "#{@app.to_s}/pkg/test-0.0.1.gem"
          File.open(path, 'w'){|f| f << "not actually a gem"}
          path
        end
        proc { @helper.install_gem }.should raise_error
      end
    end

    describe 'release' do
      it "shouldn't push if there are uncommitted files" do
        proc { @helper.release_gem }.should raise_error(/files that need to be committed/)
      end

      it 'raises an appropriate error if there is no git remote' do
        Bundler.ui.stub(:confirm => nil, :error => nil) # silence messages

        Dir.chdir(gem_repo1) {
          `git init --bare`
        }
        Dir.chdir(@app) {
          `git init`
          `git config user.email "you@example.com"`
          `git config user.name "name"`
          `git commit -a -m "initial commit"`
        }

        proc { @helper.release_gem }.should raise_error
      end

      it "releases" do
        mock_build_message
        mock_confirm_message(/Tagged v0.0.1/)
        mock_confirm_message("Pushed git commits and tags")

        @helper.should_receive(:rubygem_push).with(bundled_app('test/pkg/test-0.0.1.gem').to_s)

        Dir.chdir(gem_repo1) {
          `git init --bare`
        }
        Dir.chdir(@app) {
          `git init`
          `git config user.email "you@example.com"`
          `git config user.name "name"`
          `git remote add origin file://#{gem_repo1}`
          `git commit -a -m "initial commit"`
          sys_exec("git push origin master", true)
          `git commit -a -m "another commit"`
        }
        @helper.release_gem
      end
    end
  end
end
