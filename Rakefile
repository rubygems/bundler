# frozen_string_literal: true

$:.unshift File.expand_path("../lib", __FILE__)
require "shellwords"
require "benchmark"

NULL_DEVICE = (Gem.win_platform? ? "NUL" : "/dev/null")
RUBYGEMS_REPO = if `git -C "#{File.expand_path("..")}" remote --verbose 2> #{NULL_DEVICE}` =~ /rubygems/i
  File.expand_path("..")
else
  File.expand_path("tmp/rubygems")
end

def bundler_spec
  @bundler_spec ||= Gem::Specification.load("bundler.gemspec")
end

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
  def safe_task(&block)
    yield
    true
  rescue StandardError
    false
  end

  desc "Ensure spec dependencies are installed"
  task :deps do
    deps = Hash[bundler_spec.development_dependencies.map do |d|
      [d.name, d.requirement.to_s]
    end]

    # JRuby can't build ronn, so we skip that
    deps.delete("ronn") if defined?(RUBY_ENGINE) && RUBY_ENGINE == "jruby"

    gem_install_command = "install --no-document --conservative " + deps.sort_by {|name, _| name }.map do |name, version|
      "'#{name}:#{version}'"
    end.join(" ")
    sh %(#{Gem.ruby} -S gem #{gem_install_command})

    # Download and install gems used inside tests
    $LOAD_PATH.unshift("./spec")
    require "support/rubygems_ext"
    Spec::Rubygems.setup
  end

  namespace :travis do
    task :deps do
      # Give the travis user a name so that git won't fatally error
      system "sudo sed -i 's/1000::/1000:Travis:/g' /etc/passwd"
      # Strip secure_path so that RVM paths transmit through sudo -E
      system "sudo sed -i '/secure_path/d' /etc/sudoers"
      # Refresh packages index that the ones we need can be installed
      sh "sudo apt-get update"
      # Install groff so ronn can generate man/help pages
      sh "sudo apt-get install groff-base -y"
      # Install graphviz so that the viz specs can run
      sh "sudo apt-get install graphviz -y"

      # Install the gems with a consistent version of RubyGems
      sh "gem update --system 3.0.3"

      # Fix incorrect default gem specifications on ruby 2.6.1. Can be removed
      # when 2.6.2 is released and we start testing against it
      if RUBY_VERSION == "2.6.1"
        sh "gem install etc:1.0.1 --default"
        sh "gem install bundler:1.17.2 --default"
      end

      $LOAD_PATH.unshift("./spec")
      require "support/rubygems_ext"
      Spec::Rubygems::DEPS["codeclimate-test-reporter"] = "~> 0.6.0" if RUBY_VERSION >= "2.2.0"

      # Install the other gem deps, etc
      Rake::Task["spec:deps"].invoke
    end
  end

  task :clean do
    rm_rf "tmp"
  end

  desc "Run the real-world spec suite"
  task :realworld => %w[set_realworld spec]

  namespace :realworld do
    desc "Re-record cassettes for the realworld specs"
    task :record => %w[set_record realworld]

    task :set_record do
      ENV["BUNDLER_SPEC_FORCE_RECORD"] = "TRUE"
    end
  end

  task :set_realworld do
    ENV["BUNDLER_REALWORLD_TESTS"] = "1"
  end

  desc "Run the spec suite with the sudo tests"
  task :sudo => %w[set_sudo spec clean_sudo]

  task :set_sudo do
    ENV["BUNDLER_SUDO_TESTS"] = "1"
  end

  task :clean_sudo do
    puts "Cleaning up sudo test files..."
    system "sudo rm -rf #{File.expand_path("../tmp/sudo_gem_home", __FILE__)}"
  end

  # RubyGems specs by version
  namespace :rubygems do
    rubyopt = ENV["RUBYOPT"]
    # When editing this list, also edit .travis.yml!
    branches = %w[master]
    releases = %w[v2.5.2 v2.6.14 v2.7.9 v3.0.3]
    (branches + releases).each do |rg|
      desc "Run specs with RubyGems #{rg}"
      task rg do
        sh("bin/rspec")
      end

      # Create tasks like spec:rubygems:v1.8.3:sudo to run the sudo specs
      namespace rg do
        task :sudo => ["set_sudo", rg, "clean_sudo"]
        task :realworld => ["set_realworld", rg]
      end

      task "clone_rubygems_#{rg}" do
        unless File.directory?(RUBYGEMS_REPO)
          system("git clone https://github.com/rubygems/rubygems.git tmp/rubygems")
        end
        hash = nil

        if RUBYGEMS_REPO.start_with?(Dir.pwd)
          Dir.chdir(RUBYGEMS_REPO) do
            system("git remote update")
            if rg == "master"
              system("git checkout origin/master")
            else
              system("git checkout #{rg}") || raise("Unknown RubyGems ref #{rg}")
            end
            hash = `git rev-parse HEAD`.chomp
          end
        elsif rg != "master"
          raise "need to be running against master with bundler as a submodule"
        end

        puts "Checked out rubygems '#{rg}' at #{hash}"
        ENV["RGV"] = rg
      end

      task rg => ["clone_rubygems_#{rg}"]
      task "rubygems:all" => rg
    end

    desc "Run specs under a RubyGems checkout (set RG=path)"
    task "co" do
      sh("bin/rspec")
    end

    task "setup_co" do
      rg = File.expand_path ENV["RG"]
      puts "Running specs against RubyGems in #{rg}..."
      ENV["RUBYOPT"] = "-I#{rg} #{rubyopt}"
    end

    task "co" => "setup_co"
    task "rubygems:all" => "co"
  end

  desc "Run the tests on Travis CI against a RubyGem version (using ENV['RGV'])"
  task :travis do
    rg = ENV["RGV"] || raise("RubyGems version is required on Travis!")

    # disallow making network requests on CI
    ENV["BUNDLER_SPEC_PRE_RECORDED"] = "TRUE"

    puts "\n\e[1;33m[Travis CI] Running bundler specs against RubyGems #{rg}\e[m\n\n"
    specs = safe_task { Rake::Task["spec:rubygems:#{rg}"].invoke }

    Rake::Task["spec:rubygems:#{rg}"].reenable

    puts "\n\e[1;33m[Travis CI] Running bundler sudo specs against RubyGems #{rg}\e[m\n\n"
    sudos = system("sudo -E rake spec:rubygems:#{rg}:sudo")
    # clean up by chowning the newly root-owned tmp directory back to the travis user
    system("sudo chown -R #{ENV["USER"]} #{File.join(File.dirname(__FILE__), "tmp")}")

    Rake::Task["spec:rubygems:#{rg}"].reenable

    puts "\n\e[1;33m[Travis CI] Running bundler real world specs against RubyGems #{rg}\e[m\n\n"
    realworld = safe_task { Rake::Task["spec:rubygems:#{rg}:realworld"].invoke }

    { "specs" => specs, "sudo" => sudos, "realworld" => realworld }.each do |name, passed|
      if passed
        puts "\e[0;32m[Travis CI] #{name} passed\e[m"
      else
        puts "\e[0;31m[Travis CI] #{name} failed\e[m"
      end
    end

    unless specs && sudos && realworld
      raise "Spec run failed, please review the log for more information"
    end
  end
end

desc "Run RuboCop"
task :rubocop do
  sh("bin/rubocop --parallel")
end

begin
  require "ronn"

  namespace :man do
    directory "man"

    index = []
    sources = Dir["man/*.ronn"].map {|f| File.basename(f, ".ronn") }
    sources.map do |basename|
      ronn = "man/#{basename}.ronn"
      manual_section = ".1" unless basename =~ /\.(\d+)\Z/
      roff = "man/#{basename}#{manual_section}"

      index << [ronn, File.basename(roff)]

      file roff => ["man", ronn] do
        sh "#{Gem.ruby} -S ronn --roff --pipe #{ronn} > #{roff}"
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

    task :clean do
      leftovers = Dir["man/*"].reject do |f|
        File.extname(f) == ".ronn"
      end
      rm leftovers if leftovers.any?
    end

    desc "Build the man pages"
    task :build => ["man:clean", "man:build_all_pages"]

    desc "Remove all built man pages"
    task :clobber do
      rm_rf "lib/bundler/man"
    end

    task(:require) {}
  end
rescue LoadError
  namespace :man do
    task(:require) { abort "Install the ronn gem to be able to release!" }
    task(:build) { warn "Install the ronn gem to build the help pages" }
  end
end

begin
  require "automatiek"

  Automatiek::RakeTask.new("molinillo") do |lib|
    lib.download = { :github => "https://github.com/CocoaPods/Molinillo" }
    lib.namespace = "Molinillo"
    lib.prefix = "Bundler"
    lib.vendor_lib = "lib/bundler/vendor/molinillo"
  end

  Automatiek::RakeTask.new("thor") do |lib|
    lib.download = { :github => "https://github.com/erikhuda/thor" }
    lib.namespace = "Thor"
    lib.prefix = "Bundler"
    lib.vendor_lib = "lib/bundler/vendor/thor"
  end

  Automatiek::RakeTask.new("fileutils") do |lib|
    lib.download = { :github => "https://github.com/ruby/fileutils" }
    lib.namespace = "FileUtils"
    lib.prefix = "Bundler"
    lib.vendor_lib = "lib/bundler/vendor/fileutils"
  end

  Automatiek::RakeTask.new("net-http-persistent") do |lib|
    lib.download = { :github => "https://github.com/drbrain/net-http-persistent" }
    lib.namespace = "Net::HTTP::Persistent"
    lib.prefix = "Bundler::Persistent"
    lib.vendor_lib = "lib/bundler/vendor/net-http-persistent"

    mixin = Module.new do
      def namespace_files
        super
        require_target = vendor_lib.sub(%r{^(.+?/)?lib/}, "") << "/lib"
        relative_files = files.map {|f| Pathname.new(f).relative_path_from(Pathname.new(vendor_lib) / "lib").sub_ext("").to_s }
        process_files(/require (['"])(#{Regexp.union(relative_files)})/, "require \\1#{require_target}/\\2")
      end
    end
    lib.send(:extend, mixin)
  end
rescue LoadError
  namespace :vendor do
    task(:fileutils) { abort "Install the automatiek gem to be able to vendor gems." }
    task(:molinillo) { abort "Install the automatiek gem to be able to vendor gems." }
    task(:thor) { abort "Install the automatiek gem to be able to vendor gems." }
    task("net-http-persistent") { abort "Install the automatiek gem to be able to vendor gems." }
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

desc "Update vendored SSL certs to match the certs vendored by RubyGems"
task :update_certs => "spec:rubygems:clone_rubygems_master" do
  require "bundler/ssl_certs/certificate_manager"
  Bundler::SSLCerts::CertificateManager.update_from!(RUBYGEMS_REPO)
end

task :default => :spec

Dir["task/*.{rb,rake}"].each(&method(:load))

task :generate_files => Rake::Task.tasks.select {|t| t.name.start_with?("lib/bundler/generated") }
