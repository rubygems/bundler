require "spec_helper"

describe "bundle gem" do

  def reset!
    super
    global_config "BUNDLE_GEM__MIT" => "false", "BUNDLE_GEM__TEST" => "false", "BUNDLE_GEM__COC" => "false"
  end

  before do
    @git_name = `git config --global user.name`.chomp
    `git config --global user.name "Bundler User"`
    @git_email = `git config --global user.email`.chomp
    `git config --global user.email user@example.com`
  end

  after do
    `git config --global user.name "#{@git_name}"`
    `git config --global user.email "#{@git_email}"`
  end

  shared_examples_for "git config is present" do
    context "git config user.{name,email} present" do
      it "sets gemspec author to git user.name if available" do
        expect(generated_gem.gemspec.authors.first).to eq("Bundler User")
      end

      it "sets gemspec email to git user.email if available" do
        expect(generated_gem.gemspec.email.first).to eq("user@example.com")
      end
    end
  end

  shared_examples_for "git config is absent" do
    it "sets gemspec author to default message if git user.name is not set or empty" do
      expect(generated_gem.gemspec.authors.first).to eq("TODO: Write your name")
    end

    it "sets gemspec email to default message if git user.email is not set or empty" do
      expect(generated_gem.gemspec.email.first).to eq("TODO: Write your email address")
    end
  end

  it "generates a valid gemspec" do
    system_gems ["rake-10.0.2"]

    in_app_root
    bundle "gem newgem --bin"

    process_file(bundled_app('newgem', "newgem.gemspec")) do |line|
      next line unless line =~ /TODO/
      # Simulate replacing TODOs with real values
      case line
      when /spec\.metadata\['allowed_push_host'\]/, /spec\.homepage/
        line.gsub(/\=.*$/, "= 'http://example.org'")
      when /spec\.summary/
        line.gsub(/\=.*$/, "= %q{A short summary of my new gem.}")
      when /spec\.description/
        line.gsub(/\=.*$/, "= %q{A longer description of my new gem.}")
      else
        line
      end
    end

    Dir.chdir(bundled_app('newgem')) do
      bundle "exec rake build"
    end

    expect(exitstatus).to be_zero if exitstatus
    expect(out).not_to include("ERROR")
    expect(err).not_to include("ERROR")
  end

  context "gem naming with relative paths" do
    before do
      reset!
      in_app_root
    end

    it "resolves ." do
      create_temporary_dir('tmp')

      bundle 'gem .'

      expect(bundled_app("tmp/lib/tmp.rb")).to exist
    end

    it "resolves .." do
      create_temporary_dir('temp/empty_dir')

      bundle 'gem ..'

      expect(bundled_app("temp/lib/temp.rb")).to exist
    end

    it "resolves relative directory" do
      create_temporary_dir('tmp/empty/tmp')

      bundle 'gem ../../empty'

      expect(bundled_app("tmp/empty/lib/empty.rb")).to exist
    end

    def create_temporary_dir(dir)
      FileUtils.mkdir_p(dir)
      Dir.chdir(dir)
    end
  end

  context "gem naming with underscore" do
    let(:gem_name) { 'test_gem' }

    before do
      bundle "gem #{gem_name}"
      # reset gemspec cache for each test because of commit 3d4163a
      Bundler.clear_gemspec_cache
    end

    let(:generated_gem) { Bundler::GemHelper.new(bundled_app(gem_name).to_s) }

    it "generates a gem skeleton" do
      expect(bundled_app("test_gem/test_gem.gemspec")).to exist
      expect(bundled_app("test_gem/Gemfile")).to exist
      expect(bundled_app("test_gem/Rakefile")).to exist
      expect(bundled_app("test_gem/lib/test_gem.rb")).to exist
      expect(bundled_app("test_gem/lib/test_gem/version.rb")).to exist
      expect(bundled_app("test_gem/.gitignore")).to exist
    end

    it "starts with version 0.1.0" do
      expect(bundled_app("test_gem/lib/test_gem/version.rb").read).to match(/VERSION = "0.1.0"/)
    end

    it "does not nest constants" do
      expect(bundled_app("test_gem/lib/test_gem/version.rb").read).to match(/module TestGem/)
      expect(bundled_app("test_gem/lib/test_gem.rb").read).to match(/module TestGem/)
    end

    it_should_behave_like "git config is present"

    context "git config user.{name,email} is not set" do
      before do
        `git config --global --unset user.name`
        `git config --global --unset user.email`
        reset!
        in_app_root
        bundle "gem #{gem_name}"
      end

      it_should_behave_like "git config is absent"
    end

    it "sets gemspec metadata['allowed_push_host']", :rubygems => "2.0" do
      expect(generated_gem.gemspec.metadata['allowed_push_host']).
        to match("delete to allow pushes to any server")
    end

    it "requires the version file" do
      expect(bundled_app("test_gem/lib/test_gem.rb").read).to match(/require "test_gem\/version"/)
    end

    it "runs rake without problems" do
      system_gems ["rake-10.0.2"]

      rakefile = strip_whitespace <<-RAKEFILE
        task :default do
          puts 'SUCCESS'
        end
      RAKEFILE
      File.open(bundled_app("test_gem/Rakefile"), 'w') do |file|
        file.puts rakefile
      end

      Dir.chdir(bundled_app(gem_name)) do
        sys_exec("rake")
        expect(out).to include("SUCCESS")
      end
    end

    context "--bin parameter set" do
      before do
        reset!
        in_app_root
        bundle "gem #{gem_name} --bin"
      end

      it "builds bin skeleton" do
        expect(bundled_app("test_gem/exe/test_gem")).to exist
      end

      it "requires 'test-gem'" do
        expect(bundled_app("test_gem/exe/test_gem").read).to match(/require "test_gem"/)
      end
    end

    context "no --test parameter" do
      before do
        reset!
        in_app_root
        bundle "gem #{gem_name}"
      end

      it "doesn't create any spec/test file" do
        expect(bundled_app("test_gem/.rspec")).to_not exist
        expect(bundled_app("test_gem/spec/test_gem_spec.rb")).to_not exist
        expect(bundled_app("test_gem/spec/spec_helper.rb")).to_not exist
        expect(bundled_app("test_gem/test/test_test_gem.rb")).to_not exist
        expect(bundled_app("test_gem/test/minitest_helper.rb")).to_not exist
      end
    end

    context "--test parameter set to rspec" do
      before do
        reset!
        in_app_root
        bundle "gem #{gem_name} --test=rspec"
      end

      it "builds spec skeleton" do
        expect(bundled_app("test_gem/.rspec")).to exist
        expect(bundled_app("test_gem/spec/test_gem_spec.rb")).to exist
        expect(bundled_app("test_gem/spec/spec_helper.rb")).to exist
      end

      it "requires 'test-gem'" do
        expect(bundled_app("test_gem/spec/spec_helper.rb").read).to include("require 'test_gem'")
      end

      it "creates a default test which fails" do
        expect(bundled_app("test_gem/spec/test_gem_spec.rb").read).to include("expect(false).to eq(true)")
      end
    end

    context "gem.test setting set to rspec" do
      before do
        reset!
        in_app_root
        bundle "config gem.test rspec"
        bundle "gem #{gem_name}"
      end

      it "builds spec skeleton" do
        expect(bundled_app("test_gem/.rspec")).to exist
        expect(bundled_app("test_gem/spec/test_gem_spec.rb")).to exist
        expect(bundled_app("test_gem/spec/spec_helper.rb")).to exist
      end
    end

    context "gem.test setting set to rspec and --test is set to minitest" do
      before do
        reset!
        in_app_root
        bundle "config gem.test rspec"
        bundle "gem #{gem_name} --test=minitest"
      end

      it "builds spec skeleton" do
        expect(bundled_app("test_gem/test/test_test_gem.rb")).to exist
        expect(bundled_app("test_gem/test/minitest_helper.rb")).to exist
      end
    end

    context "--test parameter set to minitest" do
      before do
        reset!
        in_app_root
        bundle "gem #{gem_name} --test=minitest"
      end

      it "builds spec skeleton" do
        expect(bundled_app("test_gem/test/test_test_gem.rb")).to exist
        expect(bundled_app("test_gem/test/minitest_helper.rb")).to exist
      end

      it "requires 'test-gem'" do
        expect(bundled_app("test_gem/test/minitest_helper.rb").read).to include("require 'test_gem'")
      end

      it "requires 'minitest_helper'" do
        expect(bundled_app("test_gem/test/test_test_gem.rb").read).to include("require 'minitest_helper'")
      end

      it "creates a default test which fails" do
        expect(bundled_app("test_gem/test/test_test_gem.rb").read).to include("assert false")
      end
    end

    context "--test with no arguments" do
      before do
        reset!
        in_app_root
        bundle "gem #{gem_name} --test"
      end

      it "defaults to rspec" do
        expect(bundled_app("test_gem/spec/spec_helper.rb")).to exist
        expect(bundled_app("test_gem/test/minitest_helper.rb")).to_not exist
      end

      it "creates a .travis.yml file to test the library against the current Ruby version on Travis CI" do
        expect(bundled_app("test_gem/.travis.yml").read).to match(%r(- #{RUBY_VERSION}))
      end
    end

    context "--edit option" do
      it "opens the generated gemspec in the user's text editor" do
        reset!
        in_app_root
        output = bundle "gem #{gem_name} --edit=echo"
        gemspec_path = File.join(Dir.pwd, gem_name, "#{gem_name}.gemspec")
        expect(output).to include("echo \"#{gemspec_path}\"")
      end
    end
  end

  context "with --mit option" do
    let(:gem_name) { 'test-gem' }

    before do
      bundle "gem #{gem_name} --mit"
      # reset gemspec cache for each test because of commit 3d4163a
      Bundler.clear_gemspec_cache
    end

    it "generates a gem skeleton with MIT license" do
      expect(bundled_app("test-gem/test-gem.gemspec")).to exist
      expect(bundled_app("test-gem/LICENSE.txt")).to exist
      expect(bundled_app("test-gem/Gemfile")).to exist
      expect(bundled_app("test-gem/Rakefile")).to exist
      expect(bundled_app("test-gem/lib/test/gem.rb")).to exist
      expect(bundled_app("test-gem/lib/test/gem/version.rb")).to exist

      skel = Bundler::GemHelper.new(bundled_app(gem_name).to_s)
      expect(skel.gemspec.license).to eq("MIT")
    end
  end

  context "with --coc option" do
    let(:gem_name) { 'test-gem' }

    before do
      bundle "gem #{gem_name} --coc"
      # reset gemspec cache for each test because of commit 3d4163a
      Bundler.clear_gemspec_cache
    end

    it "generates a gem skeleton with Code of Conduct" do
      expect(bundled_app("test-gem/test-gem.gemspec")).to exist
      expect(bundled_app("test-gem/CODE_OF_CONDUCT.md")).to exist
      expect(bundled_app("test-gem/Gemfile")).to exist
      expect(bundled_app("test-gem/Rakefile")).to exist
      expect(bundled_app("test-gem/lib/test/gem.rb")).to exist
      expect(bundled_app("test-gem/lib/test/gem/version.rb")).to exist
    end
  end

  context "gem naming with dashed" do
    let(:gem_name) { 'test-gem' }

    before do
      bundle "gem #{gem_name}"
      # reset gemspec cache for each test because of commit 3d4163a
      Bundler.clear_gemspec_cache
    end

    let(:generated_gem) { Bundler::GemHelper.new(bundled_app(gem_name).to_s) }

    it "generates a gem skeleton" do
      expect(bundled_app("test-gem/test-gem.gemspec")).to exist
      # expect(bundled_app("test-gem/LICENSE.txt")).to exist
      expect(bundled_app("test-gem/Gemfile")).to exist
      expect(bundled_app("test-gem/Rakefile")).to exist
      expect(bundled_app("test-gem/lib/test/gem.rb")).to exist
      expect(bundled_app("test-gem/lib/test/gem/version.rb")).to exist
    end

    it "starts with version 0.1.0" do
      expect(bundled_app("test-gem/lib/test/gem/version.rb").read).to match(/VERSION = "0.1.0"/)
    end

    it "nests constants so they work" do
      expect(bundled_app("test-gem/lib/test/gem/version.rb").read).to match(/module Test\n  module Gem/)
      expect(bundled_app("test-gem/lib/test/gem.rb").read).to match(/module Test\n  module Gem/)
    end

    it_should_behave_like "git config is present"

    context "git config user.{name,email} is not set" do
      before do
        `git config --global --unset user.name`
        `git config --global --unset user.email`
        reset!
        in_app_root
        bundle "gem #{gem_name}"
      end

      it_should_behave_like "git config is absent"
    end

    it "sets gemspec metadata['allowed_push_host']", :rubygems => "2.0" do
      expect(generated_gem.gemspec.metadata['allowed_push_host']).
        to match("delete to allow pushes to any server")
    end

    it "requires the version file" do
      expect(bundled_app("test-gem/lib/test/gem.rb").read).to match(/require "test\/gem\/version"/)
    end

    it "runs rake without problems" do
      system_gems ["rake-10.0.2"]

      rakefile = strip_whitespace <<-RAKEFILE
        task :default do
          puts 'SUCCESS'
        end
      RAKEFILE
      File.open(bundled_app("test-gem/Rakefile"), 'w') do |file|
        file.puts rakefile
      end

      Dir.chdir(bundled_app(gem_name)) do
        sys_exec("rake")
        expect(out).to include("SUCCESS")
      end
    end

    context "--bin parameter set" do
      before do
        reset!
        in_app_root
        bundle "gem #{gem_name} --bin"
      end

      it "builds bin skeleton" do
        expect(bundled_app("test-gem/exe/test-gem")).to exist
      end

      it "requires 'test/gem'" do
        expect(bundled_app("test-gem/exe/test-gem").read).to match(/require "test\/gem"/)
      end
    end

    context "no --test parameter" do
      before do
        reset!
        in_app_root
        bundle "gem #{gem_name}"
      end

      it "doesn't create any spec/test file" do
        expect(bundled_app("test-gem/.rspec")).to_not exist
        expect(bundled_app("test-gem/spec/test/gem_spec.rb")).to_not exist
        expect(bundled_app("test-gem/spec/spec_helper.rb")).to_not exist
        expect(bundled_app("test-gem/test/test_test/gem.rb")).to_not exist
        expect(bundled_app("test-gem/test/minitest_helper.rb")).to_not exist
      end
    end

    context "--test parameter set to rspec" do
      before do
        reset!
        in_app_root
        bundle "gem #{gem_name} --test=rspec"
      end

      it "builds spec skeleton" do
        expect(bundled_app("test-gem/.rspec")).to exist
        expect(bundled_app("test-gem/spec/test/gem_spec.rb")).to exist
        expect(bundled_app("test-gem/spec/spec_helper.rb")).to exist
      end

      it "requires 'test/gem'" do
        expect(bundled_app("test-gem/spec/spec_helper.rb").read).to include("require 'test/gem'")
      end

      it "creates a default test which fails" do
        expect(bundled_app("test-gem/spec/test/gem_spec.rb").read).to include("expect(false).to eq(true)")
      end

      it "creates a default rake task to run the specs" do
        rakefile = strip_whitespace <<-RAKEFILE
          require "bundler/gem_tasks"
          require "rspec/core/rake_task"

          RSpec::Core::RakeTask.new(:spec)

          task :default => :spec
        RAKEFILE

        expect(bundled_app("test-gem/Rakefile").read).to eq(rakefile)
      end
    end

    context "--test parameter set to minitest" do
      before do
        reset!
        in_app_root
        bundle "gem #{gem_name} --test=minitest"
      end

      it "builds spec skeleton" do
        expect(bundled_app("test-gem/test/test_test/gem.rb")).to exist
        expect(bundled_app("test-gem/test/minitest_helper.rb")).to exist
      end

      it "requires 'test/gem'" do
        expect(bundled_app("test-gem/test/minitest_helper.rb").read).to match(/require 'test\/gem'/)
      end

      it "requires 'minitest_helper'" do
        expect(bundled_app("test-gem/test/test_test/gem.rb").read).to match(/require 'minitest_helper'/)
      end

      it "creates a default test which fails" do
        expect(bundled_app("test-gem/test/test_test/gem.rb").read).to match(/assert false/)
      end

      it "creates a default rake task to run the test suite" do
        rakefile = strip_whitespace <<-RAKEFILE
          require "bundler/gem_tasks"
          require "rake/testtask"

          Rake::TestTask.new(:test) do |t|
            t.libs << "test"
          end

          task :default => :test
        RAKEFILE

        expect(bundled_app("test-gem/Rakefile").read).to eq(rakefile)
      end
    end

    context "--test with no arguments" do
      before do
        reset!
        in_app_root
        bundle "gem #{gem_name} --test"
      end

      it "defaults to rspec" do
        expect(bundled_app("test-gem/spec/spec_helper.rb")).to exist
        expect(bundled_app("test-gem/test/minitest_helper.rb")).to_not exist
      end
    end

    context "--ext parameter set" do
      before do
        reset!
        in_app_root
        bundle "gem test_gem --ext"
      end

      it "builds ext skeleton" do
        expect(bundled_app("test_gem/ext/test_gem/extconf.rb")).to exist
        expect(bundled_app("test_gem/ext/test_gem/test_gem.h")).to exist
        expect(bundled_app("test_gem/ext/test_gem/test_gem.c")).to exist
      end

      it "includes rake-compiler" do
        expect(bundled_app("test_gem/test_gem.gemspec").read).to include('spec.add_development_dependency "rake-compiler"')
      end

      it "depends on compile task for build" do
        rakefile = strip_whitespace <<-RAKEFILE
          require "bundler/gem_tasks"
          require "rake/extensiontask"

          task :build => :compile

          Rake::ExtensionTask.new("test_gem") do |ext|
            ext.lib_dir = "lib/test_gem"
          end
        RAKEFILE

        expect(bundled_app("test_gem/Rakefile").read).to eq(rakefile)
      end
    end
  end

  context "on first run" do
    before do
      in_app_root
    end

    it "asks about test framework" do
      global_config "BUNDLE_GEM__MIT" => "false", "BUNDLE_GEM__COC" => "false"

      bundle "gem foobar" do |input|
        input.puts "rspec"
      end

      expect(bundled_app("foobar/spec/spec_helper.rb")).to exist
    end

    it "asks about MIT license" do
      global_config "BUNDLE_GEM__TEST" => "false", "BUNDLE_GEM__COC" => "false"

      bundle :config

      bundle "gem foobar" do |input|
        input.puts "yes"
      end

      expect(bundled_app("foobar/LICENSE.txt")).to exist
    end

    it "asks about CoC" do
      global_config "BUNDLE_GEM__MIT" => "false", "BUNDLE_GEM__TEST" => "false"


      bundle "gem foobar" do |input|
        input.puts "yes"
      end

      expect(bundled_app("foobar/CODE_OF_CONDUCT.md")).to exist
    end
  end

end
