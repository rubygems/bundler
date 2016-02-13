# frozen_string_literal: true
require "spec_helper"

describe "bundle help" do
  # Rubygems 1.4+ no longer load gem plugins so this test is no longer needed
  rubygems_under_14 = Gem::Requirement.new("< 1.4").satisfied_by?(Gem::Version.new(Gem::VERSION))
  it "complains if older versions of bundler are installed", :if => rubygems_under_14 do
    system_gems "bundler-0.8.1"

    bundle "help", :expect_err => true
    expect(err).to include("older than 0.9")
    expect(err).to include("running `gem cleanup bundler`.")
  end

  it "uses mann when available" do
    with_fake_man do
      bundle "help gemfile"
    end
    expect(out).to eq(%(["#{root}/lib/bundler/man/gemfile.5"]))
  end

  it "prefixes bundle commands with bundle- when finding the groff files" do
    with_fake_man do
      bundle "help install"
    end
    expect(out).to eq(%(["#{root}/lib/bundler/man/bundle-install"]))
  end

  it "simply outputs the txt file when there is no man on the path" do
    with_path_as("") do
      bundle "help install", :expect_err => true
    end
    expect(out).to match(/BUNDLE-INSTALL/)
  end

  it "still outputs the old help for commands that do not have man pages yet" do
    bundle "help check"
    expect(out).to include("Check searches the local machine")
  end

  it "looks for a binary and executes it with --help option if it's named bundler-<task>" do
    File.open(tmp("bundler-testtasks"), "w", 0755) do |f|
      f.puts "#!/usr/bin/env ruby\nputs ARGV.join(' ')\n"
    end

    with_path_added(tmp) do
      bundle "help testtasks"
    end

    expect(exitstatus).to be_zero if exitstatus
    expect(out).to eq("--help")
  end

  it "is called when the --help flag is used after the command" do
    with_fake_man do
      bundle "install --help"
    end
    expect(out).to eq(%(["#{root}/lib/bundler/man/bundle-install"]))
  end

  it "is called when the --help flag is used before the command" do
    with_fake_man do
      bundle "--help install"
    end
    expect(out).to eq(%(["#{root}/lib/bundler/man/bundle-install"]))
  end

  it "is called when the -h flag is used before the command" do
    with_fake_man do
      bundle "-h install"
    end
    expect(out).to eq(%(["#{root}/lib/bundler/man/bundle-install"]))
  end

  it "is called when the -h flag is used after the command" do
    with_fake_man do
      bundle "install -h"
    end
    expect(out).to eq(%(["#{root}/lib/bundler/man/bundle-install"]))
  end

  it "has helpful output when using --help flag for a non-existent command" do
    with_fake_man do
      bundle "instill -h", :expect_err => true
    end
    expect(err).to include('Could not find command "instill -h --no-color".')
  end
end
