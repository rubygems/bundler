require "spec_helper"
require 'rake'
require 'bundler/gem_helper'

describe Bundler::GemHelper do
  let(:app_name) { "test" }
  let(:app_path) { bundled_app app_name }
  let(:app_gemspec_path) { "#{app_path}/test.gemspec" }

  before(:each) do
    bundle "gem #{app_name}"
  end

  context "determining gemspec" do
    subject { Bundler::GemHelper.new(app_path) }

    context "fails" do
      it "when there is no gemspec" do
        FileUtils.rm app_gemspec_path
        expect { subject }.to raise_error(/Unable to determine name/)
      end

      it "when there are two gemspecs and the name isn't specified" do
        File.open(File.join(app_path.to_s, 'test2.gemspec'), "w"){ |f| f << '' }
        expect { subject }.to raise_error(/Unable to determine name/)
      end
    end

    context "interpolates the name" do
      it "when there is only one gemspec" do
        expect(subject.gemspec.name).to eq(app_name)
      end

      it "for a hidden gemspec" do
        FileUtils.mv app_gemspec_path, app_path.join('.gemspec')
        expect(subject.gemspec.name).to eq(app_name)
      end
    end

    it "handles namespaces and converts them to CamelCase" do
      bundle "gem test-foo_bar"
      app_path = bundled_app("test-foo_bar")

      lib = app_path.join("lib/test/foo_bar.rb").read
      expect(lib).to include("module Test")
      expect(lib).to include("module FooBar")
    end
  end

  context "gem management" do
    def mock_confirm_message(message)
      expect(Bundler.ui).to receive(:confirm).with(message)
    end

    def mock_build_message
      mock_confirm_message "test 0.0.1 built to pkg/test-0.0.1.gem."
    end

    subject! { Bundler::GemHelper.new(app_path) }
    let(:app_version) { "0.0.1" }
    let(:app_gem_dir) { app_path.join "pkg" }
    let(:app_gem_path) { app_gem_dir.join "#{app_name}-#{app_version}.gem" }
    let(:app_gemspec_content) { File.read(app_gemspec_path) }

    before(:each) do
      content = app_gemspec_content.gsub("TODO: ", "")
      File.open(app_gemspec_path, "w") { |file| file << content }

      @app = bundled_app("test")
      @helper = Bundler::GemHelper.new(@app.to_s)
    end

    it "uses a shell UI for output" do
      expect(Bundler.ui).to be_a(Bundler::UI::Shell)
    end

    describe "#install_tasks" do
      let!(:rake_application) { Rake.application }

      before(:each) do
        Rake.application = Rake::Application.new
      end

      after(:each) do
        Rake.application = rake_application
      end

      context "defines Rake tasks" do
        let(:task_names) { %w[build install release] }

        context "before installation" do
          it "raises an error with appropriate message" do
            task_names.each do |name|
              expect { Rake.application[name] }.
                to raise_error(/Don't know how to build task/)
            end
          end
        end

        context "after installation" do
          before do
            subject.install
          end

          it "adds Rake tasks successfully" do
            task_names.each do |name|
              expect { Rake.application[name] }.not_to raise_error
              expect(Rake.application[name]).to be_instance_of Rake::Task
            end
          end

          it "provides a way to access the gemspec object" do
            expect(subject.gemspec.name).to eq(app_name)
          end
        end
      end
    end

    describe "#build_gem" do
      context "when build failed" do
        it "raises an error with appropriate message" do
          # break the gemspec by adding back the TODOs
          File.open(app_gemspec_path, "w"){ |file| file << app_gemspec_content }
          expect { subject.build_gem }.to raise_error(/TODO/)
        end
      end

      context "when build was successful" do
        it "creates .gem file" do
          mock_build_message
          subject.build_gem
          expect(app_gem_path).to exist
        end
      end
    end

    describe "#install_gem" do
      context "when installation failed" do
        before do
          # create empty  gem file in order to simulate install failure
          subject.stub(:build_gem) do
            FileUtils.mkdir_p(app_gem_dir)
            FileUtils.touch app_gem_path
            app_gem_path
          end
        end
        it "raises an error with appropriate message" do
          expect { subject.install_gem }.to raise_error
        end
      end

      context "when installation was successful" do
        it "installs" do
          mock_build_message
          mock_confirm_message "#{app_name} (#{app_version}) installed."
          subject.install_gem
          expect(app_gem_path).to exist
          expect(`gem list`).to include("#{app_name} (#{app_version})")
        end
      end
    end

    describe "release" do
      before do
        Dir.chdir(@app) do
          `git init`
          `git config user.email "you@example.com"`
          `git config user.name "name"`
        end
      end

      it "shouldn't push if there are unstaged files" do
        expect { @helper.release_gem }.to raise_error(/files that need to be committed/)
      end

      it "shouldn't push if there are uncommitted files" do
        %x{cd test; git add .}
        expect { @helper.release_gem }.to raise_error(/files that need to be committed/)
      end

      it "raises an appropriate error if there is no git remote" do
        Bundler.ui.stub(:confirm => nil, :error => nil) # silence messages

        Dir.chdir(gem_repo1) { `git init --bare` }
        Dir.chdir(@app) { `git commit -a -m "initial commit"` }

        expect { @helper.release_gem }.to raise_error
      end

      it "releases" do
        mock_build_message
        mock_confirm_message(/Tagged v0.0.1/)
        mock_confirm_message("Pushed git commits and tags.")

        @helper.should_receive(:rubygem_push).with(bundled_app('test/pkg/test-0.0.1.gem').to_s)

        Dir.chdir(gem_repo1) { `git init --bare` }
        Dir.chdir(@app) do
          `git remote add origin file://#{gem_repo1}`
          `git commit -a -m "initial commit"`
          sys_exec("git push origin master", true)
          `git commit -a -m "another commit"`
        end
        @helper.release_gem
      end

      it "releases even if tag already exists" do
        mock_build_message
        mock_confirm_message("Tag v0.0.1 has already been created.")

        @helper.should_receive(:rubygem_push).with(bundled_app('test/pkg/test-0.0.1.gem').to_s)

        Dir.chdir(gem_repo1) {
          `git init --bare`
        }
        Dir.chdir(@app) {
          `git init`
          `git config user.email "you@example.com"`
          `git config user.name "name"`
          `git commit -a -m "another commit"`
          `git tag -a -m \"Version 0.0.1\" v0.0.1`
        }
        @helper.release_gem
      end

    end
  end
end
