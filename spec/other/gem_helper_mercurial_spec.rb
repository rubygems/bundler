require "spec_helper"
require 'bundler/gem_helper_mercurial'

describe "Bundler::GemHelperMercurial tasks" do
  context "gem cli command" do
    it "should generate .hgignore instead of .gitignore with -H flag" do
      bundle 'gem test -H'
      app = bundled_app("test")
      helper = Bundler::GemHelperMercurial.new(app.to_s)
      helper.gemspec.name.should == 'test'
      File.exist?("#{app.to_s}/.hgignore").should be_true
      File.exist?("#{app.to_s}/.gitignore").should be_false
    end

    it "should work as expected without -H flag" do
      bundle 'gem test'
      app = bundled_app("test")
      helper = Bundler::GemHelperMercurial.new(app.to_s)
      helper.gemspec.name.should == 'test'
      File.exist?("#{app.to_s}/.hgignore").should be_false
      File.exist?("#{app.to_s}/.gitignore").should be_true
      rakefile = File.open("#{app.to_s}/Rakefile", 'r') {|f| f.readlines.map() {|line| line.strip}}
      rakefile.should include("Bundler::GemHelper.install_tasks")
      rakefile.should_not include("Bundler::GemHelperMercurial.install_tasks")
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
      bundle 'gem test -H'
      @app = bundled_app("test")
      @gemspec = File.read("#{@app.to_s}/test.gemspec")
      File.open("#{@app.to_s}/test.gemspec", 'w'){|f| f << @gemspec.gsub('TODO: ', '') }
      File.open("#{@app.to_s}/.hg/hgrc", 'w') { |f| f << "[ui]\nusername = Me The Tester<me@tester.com>\n"}
      @helper = Bundler::GemHelperMercurial.new(@app.to_s)
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


        Dir.chdir(@app) {
          #`hg init .`
          `hg commit -m "initial commit"`
        }

        proc { @helper.release_gem }.should raise_error
      end

      it "releases" do
        mock_build_message
        mock_confirm_message(/Tagged v0.0.1/)
        mock_confirm_message("Pushed hg commits and tags for the current branch")

        @helper.should_receive(:rubygem_push).with(bundled_app('test/pkg/test-0.0.1.gem').to_s)

        Dir.chdir(gem_repo1) {
          `hg init .`
        }
        Dir.chdir(@app) {
          #`hg init .`
          open('.hg/hgrc', 'a') { |f| f << "[paths]\ndefault = #{gem_repo1}\n"}
          `hg commit -m "initial commit"`
          Open3.popen3("hg push") # use popen3 to silence output...
          `hg commit -m "another commit"`
        }
        @helper.release_gem
      end
    end
  end
end
