# -*- encoding: utf-8 -*-
$:.unshift File.expand_path("../lib", __FILE__)
require 'rubygems'
require 'bundler/gem_tasks'

task :release => ["man:clean", "man:build"]

def safe_task(&block)
  yield
  true
rescue
  false
end

def sudo_task(task)
  system("sudo -E rake #{task}")
end

namespace :spec do
  desc "Ensure spec dependencies are installed"
  task :deps do
    sh "#{Gem.ruby} -S gem list ronn | (grep 'ronn' 1> /dev/null) || #{Gem.ruby} -S gem install ronn --no-ri --no-rdoc"
    sh "#{Gem.ruby} -S gem list rspec | (grep 'rspec (2.' 1> /dev/null) || #{Gem.ruby} -S gem install rspec --no-ri --no-rdoc"
  end
end

begin
  # running the specs needs both rspec and ronn
  require 'rspec/core/rake_task'
  require 'ronn'

  desc "Run specs"
  RSpec::Core::RakeTask.new do |t|
    t.rspec_opts = %w(-fs --color)
    t.ruby_opts  = %w(-w)
  end
  task :spec => "man:build"

  namespace :spec do
    task :clean do
      rm_rf 'tmp'
    end

    desc "Run the real-world spec suite (requires internet)"
    task :realworld => ["set_realworld", "spec"]

    task :set_realworld do
      ENV['BUNDLER_REALWORLD_TESTS'] = '1'
    end

    desc "Run the spec suite with the sudo tests"
    task :sudo => ["set_sudo", "spec", "clean_sudo"]

    task :set_sudo do
      ENV['BUNDLER_SUDO_TESTS'] = '1'
    end

    task :clean_sudo do
      puts "Cleaning up sudo test files..."
      system "sudo rm -rf #{File.expand_path('../tmp/sudo_gem_home', __FILE__)}"
    end

    namespace :rubygems do
      # Rubygems specs by version
      rubyopt = ENV["RUBYOPT"]
      %w(master v1.3.6 v1.3.7 v1.4.2 v1.5.3 v1.6.2 v1.7.2 v1.8.24).each do |rg|
        desc "Run specs with Rubygems #{rg}"
        RSpec::Core::RakeTask.new(rg) do |t|
          t.rspec_opts = %w(-fs --color)
          t.ruby_opts  = %w(-w)
        end

        # Create tasks like spec:rubygems:v1.8.3:sudo to run the sudo specs
        namespace rg do
          task :sudo => ["set_sudo", rg, "clean_sudo"]
          task :realworld => ["set_realworld", rg]
        end

        task "clone_rubygems_#{rg}" do
          unless File.directory?("tmp/rubygems")
            system("git clone git://github.com/rubygems/rubygems.git tmp/rubygems")
          end
          hash = nil

          Dir.chdir("tmp/rubygems") do
            system("git remote update")
            system("git checkout #{rg}")
            system("git pull origin master") if rg == "master"
            hash = `git rev-parse HEAD`.strip
          end

          puts "Running bundler specs against rubygems '#{rg}' at #{hash}"
          ENV["RUBYOPT"] = "-I#{File.expand_path("tmp/rubygems/lib")} #{rubyopt}"
        end

        task rg => ["clone_rubygems_#{rg}", "man:build"]
        task "rubygems:all" => rg
      end

      desc "Run specs under a Rubygems checkout (set RG=path)"
      RSpec::Core::RakeTask.new("co") do |t|
        t.rspec_opts = %w(-fs --color)
        t.ruby_opts  = %w(-w)
      end

      task "setup_co" do
        ENV["RUBYOPT"] = "-I#{File.expand_path ENV['RG']} #{rubyopt}"
      end

      task "co" => "setup_co"
      task "rubygems:all" => "co"
    end

    desc "Run the tests on Travis CI against a rubygem version (using ENV['RGV'])"
    task :travis do
      rg = ENV['RGV'] || 'master'

      puts "\n\e[1;33m[Travis CI] Running bundler specs against rubygems #{rg}\e[m\n\n"
      specs = safe_task { Rake::Task["spec:rubygems:#{rg}"].invoke }

      Rake::Task["spec:rubygems:#{rg}"].reenable

      puts "\n\e[1;33m[Travis CI] Running bundler sudo specs against rubygems #{rg}\e[m\n\n"
      sudos = sudo_task "spec:rubygems:#{rg}:sudo"
      chown = system("sudo chown -R #{ENV['USER']} #{File.join(File.dirname(__FILE__), 'tmp')}")

      Rake::Task["spec:rubygems:#{rg}"].reenable

      puts "\n\e[1;33m[Travis CI] Running bundler real world specs against rubygems #{rg}\e[m\n\n"
      realworld = safe_task { Rake::Task["spec:rubygems:#{rg}:realworld"].invoke }

      unless specs && sudos && realworld
        fail "Bundler tests failed, please review the log for more information"
      end
    end
  end

  namespace :man do
    directory "lib/bundler/man"

    Dir["man/*.ronn"].each do |ronn|
      basename = File.basename(ronn, ".ronn")
      roff = "lib/bundler/man/#{basename}"

      file roff => ["lib/bundler/man", ronn] do
        sh "#{Gem.ruby} -S ronn --roff --pipe #{ronn} > #{roff}"
      end

      file "#{roff}.txt" => roff do
        sh "groff -Wall -mtty-char -mandoc -Tascii #{roff} | col -b > #{roff}.txt"
      end

      task :build_all_pages => "#{roff}.txt"
    end

    desc "Build the man pages"
    task :build => "man:build_all_pages"

    desc "Clean up from the built man pages"
    task :clean do
      rm_rf "lib/bundler/man"
    end
  end

  begin
    require 'ci/reporter/rake/rspec'

    namespace :ci do
      desc "Run specs with Hudson output"
      RSpec::Core::RakeTask.new(:spec)
      task :spec => ["ci:setup:rspec", "man:build"]
    end

  rescue LoadError
    namespace :ci do
      task :spec do
        abort "Run `rake ci:deps` to be able to run the CI specs"
      end

      desc "Install CI dependencies"
      task :deps do
        sh "#{Gem.ruby} -S gem list ci_reporter | (grep 'ci_reporter' 1> /dev/null) || #{Gem.ruby} -S gem install ci_reporter --no-ri --no-rdoc"
      end
      task :deps => "spec:deps"
    end
  end

rescue LoadError
  task :spec do
    abort "Run `rake spec:deps` to be able to run the specs"
  end
end

namespace :vendor do
  desc "Build the vendor dir"
  task :build => :clean do
    sh "git clone git://github.com/wycats/thor.git lib/bundler/vendor/tmp"
    sh "mv lib/bundler/vendor/tmp/lib/* lib/bundler/vendor/"
    rm_rf "lib/bundler/vendor/tmp"
  end

  desc "Clean the vendor dir"
  task :clean do
    rm_rf "lib/bundler/vendor"
  end
end

task :default => :spec
