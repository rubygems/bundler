# frozen_string_literal: true
require "spec_helper"

describe "bundler/inline#gemfile" do
  def script(code, options = {})
    requires = ["bundler/inline"]
    requires.unshift File.expand_path("../../support/artifice/" + options.delete(:artifice) + ".rb", __FILE__) if options.key?(:artifice)
    requires = requires.map {|r| "require '#{r}'" }.join("\n")
    @out = ruby("#{requires}\n\n" + code, options)
  end

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

    build_lib "eight", "1.0.0" do |s|
      s.write "lib/eight.rb", "puts 'eight'"
    end

    build_lib "four", "1.0.0" do |s|
      s.write "lib/four.rb", "puts 'four'"
    end
  end

  it "requires the gems" do
    script <<-RUBY
      gemfile do
        path "#{lib_path}"
        gem "two"
      end
    RUBY

    expect(out).to eq("two")
    expect(exitstatus).to be_zero if exitstatus

    script <<-RUBY, :expect_err => true
      gemfile do
        path "#{lib_path}"
        gem "eleven"
      end

      puts "success"
    RUBY

    expect(err).to include "Could not find gem 'eleven'"
    expect(out).not_to include "success"

    script <<-RUBY
      gemfile(true) do
        source "file://#{gem_repo1}"
        gem "rack"
      end
    RUBY

    expect(out).to include("Rack's post install message")
    expect(exitstatus).to be_zero if exitstatus

    script <<-RUBY, :artifice => "endpoint"
      gemfile(true) do
        source "https://rubygems.org"
        gem "activesupport", :require => true
      end
    RUBY

    expect(out).to include("Installing activesupport")
    expect(err).to eq("")
    expect(exitstatus).to be_zero if exitstatus
  end

  it "lets me use my own ui object" do
    script <<-RUBY, :artifice => "endpoint"
      require 'bundler'
      class MyBundlerUI < Bundler::UI::Silent
        def confirm(msg, newline = nil)
          puts "CONFIRMED!"
        end
      end
      gemfile(true, :ui => MyBundlerUI.new) do
        source "https://rubygems.org"
        gem "activesupport", :require => true
      end
    RUBY

    expect(out).to eq("CONFIRMED!")
    expect(exitstatus).to be_zero if exitstatus
  end

  it "raises an exception if passed unknown arguments" do
    script <<-RUBY, :expect_err => true
      gemfile(true, :arglebargle => true) do
        path "#{lib_path}"
        gem "two"
      end

      puts "success"
    RUBY
    expect(err).to include "Unknown options: arglebargle"
    expect(out).not_to include "success"
  end

  it "does not mutate the option argument" do
    script <<-RUBY
      require 'bundler'
      options = { :ui => Bundler::UI::Shell.new }
      gemfile(false, options) do
        path "#{lib_path}"
        gem "two"
      end
      puts "OKAY" if options.key?(:ui)
    RUBY

    expect(out).to match("OKAY")
    expect(exitstatus).to be_zero if exitstatus
  end

  it "installs quietly if necessary when the install option is not set" do
    script <<-RUBY
      gemfile do
        source "file://#{gem_repo1}"
        gem "rack"
      end

      puts RACK
    RUBY

    expect(out).to eq("1.0.0")
    expect(err).to be_empty
    expect(exitstatus).to be_zero if exitstatus
  end
end
