# frozen_string_literal: true

require "benchmark"

require_relative "spec/support/rubygems_ext"

# Benchmark task execution
module Rake
  class Task
    alias_method :real_invoke, :invoke

    def invoke(*args)
      time = Benchmark.measure(@name) do
        real_invoke(*args)
      end
      puts "#{@name} ran for #{time}"
    end
  end
end

desc "Run specs"
task :spec do
  sh("bin/rspec")
end

namespace :spec do
  desc "Ensure spec dependencies are installed"
  task :deps do
    Spec::Rubygems.dev_setup

    Spec::Rubygems.install_test_deps
  end

  desc "Ensure spec dependencies for running in parallel are installed"
  task :parallel_deps do
    Spec::Rubygems.dev_setup

    Spec::Rubygems.install_parallel_test_deps
  end

  desc "Run the real-world spec suite"
  task :realworld => %w[set_realworld spec]

  namespace :realworld do
    desc "Re-record cassettes for the realworld specs"
    task :record => %w[set_record realworld]

    task :set_record do
      ENV["BUNDLER_SPEC_FORCE_RECORD"] = "1"
    end
  end

  task :set_realworld do
    ENV["BUNDLER_REALWORLD_TESTS"] = "1"
  end

  desc "Run the spec suite with the sudo tests"
  task :sudo => %w[set_sudo spec]

  task :set_sudo do
    ENV["BUNDLER_SUDO_TESTS"] = "1"
  end
end

desc "Run RuboCop"
task :rubocop do
  sh("bin/rubocop --parallel")
end

desc "Check RVM integration"
task :check_rvm_integration do
  # The rubygems-bundler gem is installed by RVM by default and it could easily
  # break when we change bundler. Make sure that binstubs still run with it
  # installed.
  sh("gem install rubygems-bundler && RUBYOPT=-Ilib rake -T")
end

namespace :man do
  if RUBY_ENGINE == "jruby"
    task(:build) {}
  else
    begin
      Spec::Rubygems.gem_require("ronn")
    rescue Gem::LoadError => e
      desc "Build the man pages"
      task(:build) { abort "We couln't activate ronn (#{e.requirement}). Try `gem install ronn:'#{e.requirement}'` to be able to build the help pages" }

      desc "Verify man pages are in sync"
      task(:check) { abort "We couln't activate ronn (#{e.requirement}). Try `gem install ronn:'#{e.requirement}'` to be able to build the help pages" }
    else
      directory "man"

      index = []
      sources = Dir["man/*.ronn"].map {|f| File.basename(f, ".ronn") }
      sources.map do |basename|
        ronn = "man/#{basename}.ronn"
        manual_section = ".1" unless basename =~ /\.(\d+)\Z/
        roff = "man/#{basename}#{manual_section}"

        index << [ronn, File.basename(roff)]

        file roff => ["man", ronn] do
          sh "bin/ronn --roff --pipe --date #{Time.now.strftime("%Y-%m-%d")} #{ronn} > #{roff}"
        end

        file "#{roff}.txt" => roff do
          sh "groff -Wall -mtty-char -mandoc -Tascii #{roff} | col -b > #{roff}.txt"
        end

        task :build_all_pages => "#{roff}.txt"
      end

      file "index.txt" do
        index.map! do |(ronn, roff)|
          [File.read(ronn).split(" ").first, roff]
        end
        index = index.sort_by(&:first)
        justification = index.map {|(n, _f)| n.length }.max + 4
        File.open("man/index.txt", "w") do |f|
          index.each do |name, filename|
            f << name.ljust(justification) << filename << "\n"
          end
        end
      end
      task :build_all_pages => "index.txt"

      desc "Remove all built man pages"
      task :clean do
        leftovers = Dir["man/*"].reject do |f|
          File.extname(f) == ".ronn"
        end
        rm leftovers if leftovers.any?
      end

      desc "Build the man pages"
      task :build => ["man:clean", "man:build_all_pages"]

      desc "Verify man pages are in sync"
      task :check => :build do
        sh("git diff --quiet --ignore-all-space man") do |outcome, _|
          if outcome
            puts
            puts "Manpages are in sync!"
            puts
          else
            sh("GIT_PAGER=cat git diff --ignore-all-space man")

            puts
            puts "Man pages are out of sync. Above you can see the diff that got generated from rebuilding them. Please review and commit the results."
            puts

            exit(1)
          end
        end
      end
    end
  end
end

begin
  Spec::Rubygems.gem_require("automatiek")
rescue Gem::LoadError => e
  msg = "We couldn't activate automatiek (#{e.requirement}). Try `gem install automatiek:'#{e.requirement}'` to be able to vendor gems"

  namespace :vendor do
    desc "Vendor a specific version of molinillo"
    task(:molinillo) { abort msg }

    desc "Vendor a specific version of fileutils"
    task(:fileutils) { abort msg }

    desc "Vendor a specific version of thor"
    task(:thor) { abort msg }

    desc "Vendor a specific version of net-http-persistent"
    task(:"net-http-persistent") { abort msg }
  end
else
  desc "Vendor a specific version of molinillo"
  Automatiek::RakeTask.new("molinillo") do |lib|
    lib.download = { :github => "https://github.com/CocoaPods/Molinillo" }
    lib.namespace = "Molinillo"
    lib.prefix = "Bundler"
    lib.vendor_lib = "lib/bundler/vendor/molinillo"
  end

  # We currently cherry-pick changes to use `require_relative` internally
  # instead of regular `require`. They are already in thor's master branch but
  # still need to be released.
  desc "Vendor a specific version of thor"
  Automatiek::RakeTask.new("thor") do |lib|
    lib.download = { :github => "https://github.com/erikhuda/thor" }
    lib.namespace = "Thor"
    lib.prefix = "Bundler"
    lib.vendor_lib = "lib/bundler/vendor/thor"
  end

  desc "Vendor a specific version of fileutils"
  Automatiek::RakeTask.new("fileutils") do |lib|
    lib.download = { :github => "https://github.com/ruby/fileutils" }
    lib.namespace = "FileUtils"
    lib.prefix = "Bundler"
    lib.vendor_lib = "lib/bundler/vendor/fileutils"
  end

  # We currently cherry-pick changes to use `require_relative` internally
  # instead of regular `require`. They are pending review at
  # https://github.com/drbrain/net-http-persistent/pull/106
  desc "Vendor a specific version of net-http-persistent"
  Automatiek::RakeTask.new("net-http-persistent") do |lib|
    lib.download = { :github => "https://github.com/drbrain/net-http-persistent" }
    lib.namespace = "Net::HTTP::Persistent"
    lib.prefix = "Bundler::Persistent"
    lib.vendor_lib = "lib/bundler/vendor/net-http-persistent"

    lib.dependency("connection_pool") do |sublib|
      sublib.version = "v2.2.2"
      sublib.download = { :github => "https://github.com/mperham/connection_pool" }
      sublib.namespace = "ConnectionPool"
      sublib.prefix = "Bundler"
      sublib.vendor_lib = "lib/bundler/vendor/connection_pool"
    end

    lib.dependency("uri") do |sublib|
      sublib.version = "master"
      sublib.download = { :github => "https://github.com/ruby/uri" }
      sublib.namespace = "URI"
      sublib.prefix = "Bundler"
      sublib.vendor_lib = "lib/bundler/vendor/uri"
    end
  end
end

task :override_version do
  next unless version = ENV["BUNDLER_SPEC_SUB_VERSION"]
  version_file = File.expand_path("../lib/bundler/version.rb", __FILE__)
  contents = File.read(version_file)
  unless contents.sub!(/(^\s+VERSION\s*=\s*)"#{Gem::Version::VERSION_PATTERN}"/, %(\\1"#{version}"))
    abort("Failed to change bundler version")
  end
  File.open(version_file, "w") {|f| f << contents }
end

task :default => :spec

Dir["task/*.rake"].each(&method(:load))
