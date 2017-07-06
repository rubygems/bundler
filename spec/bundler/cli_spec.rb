# frozen_string_literal: true
require "bundler/cli"
require "bundler/friendly_errors"

RSpec.describe "bundle executable" do
  it "returns non-zero exit status when passed unrecognized options" do
    bundle_command "--invalid_argument"
    expect(last_command).to be_failure
    expect(last_command.bundler_err).to eq "Unknown switches '--invalid_argument'"
  end

  it "returns non-zero exit status when passed unrecognized task" do
    bundle_command "unrecognized-task"
    expect(last_command).to be_failure
    expect(last_command.bundler_err).to eq 'Could not find command "unrecognized-task".'
  end

  it "looks for a binary and executes it if it's named bundler-<task>" do
    File.open(tmp("bundler-testtasks"), "w", 0o755) do |f|
      f.puts "#!/usr/bin/env ruby\nputs 'Hello, world'\n"
    end

    expect(Kernel).to receive(:exec).with(tmp("bundler-testtasks").to_s)
    with_path_added(tmp) do
      bundle_command! "testtasks"
    end
  end

  context "with --verbose" do
    it "prints the running command" do
      bundle_command! :config, :verbose => true
      expect(last_command.stdout).to start_with("Running `bundle config --verbose` with bundler #{Bundler::VERSION}")
    end

    it "doesn't print defaults" do
      gemfile ""
      bundle_command! :install, :verbose => true, :retry => 0, :"no-color" => true
      expect(last_command.stdout).to start_with("Running `bundle install --no-color --retry 0 --verbose` with bundler #{Bundler::VERSION}")
    end
  end

  describe "printing the outdated warning" do
    shared_examples_for "no warning" do
      it "prints no warning" do
        bundle_command "fail"
        expect(last_command.stdboth).to eq("Could not find command \"fail\".")
      end
    end

    let(:bundler_version) { "1.1" }
    let(:latest_version) { nil }
    before do
      simulate_bundler_version(bundler_version)
      if latest_version
        info_path = home(".bundle/cache/compact_index/rubygems.org.443.29b0360b937aa4d161703e6160654e47/info/bundler")
        info_path.parent.mkpath
        info_path.open("w") {|f| f.write "#{latest_version}\n" }
      end
    end

    context "when there is no latest version" do
      include_examples "no warning"
    end

    context "when the latest version is equal to the current version" do
      let(:latest_version) { bundler_version }
      include_examples "no warning"
    end

    context "when the latest version is less than the current version" do
      let(:latest_version) { "0.9" }
      include_examples "no warning"
    end

    context "when the latest version is greater than the current version" do
      let(:latest_version) { "2.0" }
      it "prints the version warning" do
        bundle_command "fail"
        expect(last_command.stdout).to start_with(<<-EOS.strip)
The latest bundler is #{latest_version}, but you are currently running #{bundler_version}.
To update, run `gem install bundler`
        EOS
      end

      context "and disable_version_check is set" do
        before { bundle! "config disable_version_check true" }
        include_examples "no warning"
      end

      context "and is a pre-release" do
        let(:latest_version) { "2.0.0.pre.4" }
        it "prints the version warning" do
          bundle "fail"
          expect(last_command.stdout).to start_with(<<-EOS.strip)
The latest bundler is #{latest_version}, but you are currently running #{bundler_version}.
To update, run `gem install bundler --pre`
          EOS
        end
      end
    end
  end
end

RSpec.describe "bundler executable" do
  it "shows the bundler version just as the `bundle` executable does" do
    bundle_command "--version", :exe => bundle_exe("bundler")
    expect(out).to eq("Bundler version #{Bundler::VERSION}")
  end
end
