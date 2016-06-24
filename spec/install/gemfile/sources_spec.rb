# frozen_string_literal: true
require "spec_helper"

describe "bundle install with gems on multiple sources" do
  # repo1 is built automatically before all of the specs run
  # it contains rack-obama 1.0.0 and rack 0.9.1 & 1.0.0 amongst other gems

  context "without source affinity" do
    before do
      # Oh no! Someone evil is trying to hijack rack :(
      # need this to be broken to check for correct source ordering
      build_repo gem_repo3 do
        build_gem "rack", repo3_rack_version do |s|
          s.write "lib/rack.rb", "RACK = 'FAIL'"
        end
      end
    end

    context "with multiple toplevel sources" do
      let(:repo3_rack_version) { "1.0.0" }

      before do
        gemfile <<-G
          source "file://#{gem_repo3}"
          source "file://#{gem_repo1}"
          gem "rack-obama"
          gem "rack"
        G
      end

      it "errors when disable_multisource is set" do
        bundle "config disable_multisource true"
        bundle :install, :expect_err => true
        expect(err).to include("Each source after the first must include a block")
        expect(exitstatus).to eq(14) if exitstatus
      end
    end

    context "when different versions of the same gem are in multiple sources" do
      let(:repo3_rack_version) { "1.2" }

      before do
        gemfile <<-G
          source "file://#{gem_repo3}"
          source "file://#{gem_repo1}"
          gem "rack-obama"
          gem "rack", "1.0.0" # force it to install the working version in repo1
        G
      end
    end
  end

  context "with source affinity" do
    context "with sources given by a block" do
      before do
        # Oh no! Someone evil is trying to hijack rack :(
        # need this to be broken to check for correct source ordering
        build_repo gem_repo3 do
          build_gem "rack", "1.0.0" do |s|
            s.write "lib/rack.rb", "RACK = 'FAIL'"
          end

          build_gem "rack-obama" do |s|
            s.add_dependency "rack"
          end
        end

        gemfile <<-G
          source "file://#{gem_repo3}"
          source "file://#{gem_repo1}" do
            gem "thin" # comes first to test name sorting
            gem "rack"
          end
          gem "rack-obama" # shoud come from repo3!
        G
      end

      it "installs the gems without any warning" do
        bundle! :install
        expect(out).not_to include("Warning")
        should_be_installed("rack-obama 1.0.0", "rack 1.0.0")
      end
    end

    context "with sources set by an option" do
      before do
        # Oh no! Someone evil is trying to hijack rack :(
        # need this to be broken to check for correct source ordering
        build_repo gem_repo3 do
          build_gem "rack", "1.0.0" do |s|
            s.write "lib/rack.rb", "RACK = 'FAIL'"
          end

          build_gem "rack-obama" do |s|
            s.add_dependency "rack"
          end
        end

        gemfile <<-G
          source "file://#{gem_repo3}"
          gem "rack-obama" # should come from repo3!
          gem "rack", :source => "file://#{gem_repo1}"
        G
      end

      it "installs the gems without any warning" do
        bundle! :install
        expect(out).not_to include("Warning")
        should_be_installed("rack-obama 1.0.0", "rack 1.0.0")
      end
    end

    context "when a pinned gem has an indirect dependency" do
      before do
        build_repo gem_repo3 do
          build_gem "depends_on_rack", "1.0.1" do |s|
            s.add_dependency "rack"
          end
        end
      end

      context "when the indirect dependency is in the pinned source" do
        before do
          # we need a working rack gem in repo3
          update_repo gem_repo3 do
            build_gem "rack", "1.0.0"
          end

          gemfile <<-G
            source "file://#{gem_repo2}"
            source "file://#{gem_repo3}" do
              gem "depends_on_rack"
            end
          G
        end

        context "and not in any other sources" do
          before do
            build_repo(gem_repo2) {}
          end

          it "installs from the same source without any warning" do
            bundle :install
            expect(out).not_to include("Warning")
            should_be_installed("depends_on_rack 1.0.1", "rack 1.0.0")
          end
        end

        context "and in another source" do
          before do
            # need this to be broken to check for correct source ordering
            build_repo gem_repo2 do
              build_gem "rack", "1.0.0" do |s|
                s.write "lib/rack.rb", "RACK = 'FAIL'"
              end
            end
          end

          it "installs from the same source without any warning" do
            bundle :install
            expect(out).not_to include("Warning")
            should_be_installed("depends_on_rack 1.0.1", "rack 1.0.0")
          end
        end
      end

      context "when the indirect dependency is in a different source" do
        before do
          # In these tests, we need a working rack gem in repo2 and not repo3
          build_repo gem_repo2 do
            build_gem "rack", "1.0.0"
          end
        end

        context "and not in any other sources" do
          before do
            gemfile <<-G
              source "file://#{gem_repo2}"
              source "file://#{gem_repo3}" do
                gem "depends_on_rack"
              end
            G
          end

          it "installs from the other source without any warning" do
            bundle :install
            expect(out).not_to include("Warning")
            should_be_installed("depends_on_rack 1.0.1", "rack 1.0.0")
          end
        end

        context "and in yet another source" do
          before do
            gemfile <<-G
              source "file://#{gem_repo1}"
              source "file://#{gem_repo2}"
              source "file://#{gem_repo3}" do
                gem "depends_on_rack"
              end
            G
          end

          pending "this should have a test or be removed"
        end

        context "and only the dependency is pinned" do
          before do
            # need this to be broken to check for correct source ordering
            build_repo gem_repo2 do
              build_gem "rack", "1.0.0" do |s|
                s.write "lib/rack.rb", "RACK = 'FAIL'"
              end
            end

            gemfile <<-G
              source "file://#{gem_repo3}" # contains depends_on_rack
              source "file://#{gem_repo2}" # contains broken rack

              gem "depends_on_rack" # installed from gem_repo3
              gem "rack", :source => "file://#{gem_repo1}"
            G
          end

          pending "this should have a test or be removed"
        end
      end
    end

    context "installing with dependencies from a monorepo" do
      def should_be_installed_from_source(names_and_sources)
        names_and_sources.each do |full_name, source|
          should_be_installed full_name
          name = full_name.split(" ", 2).first
          run! <<-R
            begin
              require '#{name}/source.rb'
              puts #{Spec::Builders.constantize(name)}_SOURCE
            rescue LoadError, NameError
              puts
            end
          R
          expect(out).to eq(source.to_s), "#{full_name} came from #{out.inspect} instead of #{source.inspect}"
        end
      end

      before do
        build_lib "actionpack", "2.3.2", :path => lib_path("rails-2.3.2/actionpack") do |s|
          s.write "lib/#{s.name}/source.rb", "#{Spec::Builders.constantize(s.name)}_SOURCE = 'rails-git'"
          s.add_dependency "activesupport", "2.3.2"
        end
        build_lib "activerecord", "2.3.2", :path => lib_path("rails-2.3.2/activerecord") do |s|
          s.write "lib/#{s.name}/source.rb", "#{Spec::Builders.constantize(s.name)}_SOURCE = 'rails-git'"
          s.add_dependency "activesupport", "2.3.2"
        end
        build_lib "actionmailer", "2.3.2", :path => lib_path("rails-2.3.2/actionmailer") do |s|
          s.write "lib/#{s.name}/source.rb", "#{Spec::Builders.constantize(s.name)}_SOURCE = 'rails-git'"
          s.add_dependency "activesupport", "2.3.2"
        end
        build_lib "activeresource", "2.3.2", :path => lib_path("rails-2.3.2/activeresource") do |s|
          s.write "lib/#{s.name}/source.rb", "#{Spec::Builders.constantize(s.name)}_SOURCE = 'rails-git'"
          s.add_dependency "activesupport", "2.3.2"
        end
        build_lib "activesupport", "2.3.2", :path => lib_path("rails-2.3.2/activesupport") do |s|
          s.write "lib/#{s.name}/source.rb", "#{Spec::Builders.constantize(s.name)}_SOURCE = 'rails-git'"
        end
        build_git "rails", "2.3.2" do |s|
          s.write "lib/#{s.name}/source.rb", "#{Spec::Builders.constantize(s.name)}_SOURCE = 'rails-git'"
          s.executables = "rails"
          s.add_dependency "rake",           "10.0.2"
          s.add_dependency "actionpack",     s.version
          s.add_dependency "activerecord",   s.version
          s.add_dependency "actionmailer",   s.version
          s.add_dependency "activeresource", s.version
        end
      end

      context "when depending on rails via git without a rubygems source" do
        before do
          build_lib "rake", "10.0.2" do |s|
            s.write "lib/rake/source.rb", "RAKE_SOURCE = 'rake-git'"
          end
          install_gemfile <<-G
            gem "rake", :path => #{lib_path("rake-10.0.2").to_s.dump}
            gem "rails", :git => #{lib_path("rails-2.3.2").to_s.dump}
          G
        end

        it "pulls all dependencies from the rails repo" do
          should_be_installed_from_source("actionmailer 2.3.2" => "rails-git",
                                          "actionpack 2.3.2" => "rails-git",
                                          "activerecord 2.3.2" => "rails-git",
                                          "activeresource 2.3.2" => "rails-git",
                                          "activesupport 2.3.2" => "rails-git",
                                          "rails 2.3.2" => "rails-git",
                                          "rake 10.0.2" => "rake-git")
        end
      end

      context "when depending on rails via git with a rubygems source" do
        before do
          update_repo gem_repo1 do
            build_gem "rake", "10.0.2"
          end
          install_gemfile <<-G
            source "file://#{gem_repo1}/"
            gem "rails", :git => #{lib_path("rails-2.3.2").to_s.dump}
          G
        end

        it "pulls all dependencies from the rails repo" do
          should_be_installed_from_source("actionmailer 2.3.2" => "rails-git",
                                          "actionpack 2.3.2" => "rails-git",
                                          "activerecord 2.3.2" => "rails-git",
                                          "activeresource 2.3.2" => "rails-git",
                                          "activesupport 2.3.2" => "rails-git",
                                          "rails 2.3.2" => "rails-git",
                                          "rake 10.0.2" => nil)
        end
      end

      context "when depending on rails via git with a rubygems source and a transitive dep is made explicit" do
        before do
          update_repo gem_repo1 do
            build_gem "rake", "10.0.2"
          end
          install_gemfile <<-G
            source "file://#{gem_repo1}/"
            gem "rails", :git => #{lib_path("rails-2.3.2").to_s.dump}
            gem "actionmailer"
          G
        end

        it "pulls all dependencies from the rails repo" do
          should_be_installed_from_source("actionmailer 2.3.2" => nil,
                                          "actionpack 2.3.2" => "rails-git",
                                          "activerecord 2.3.2" => "rails-git",
                                          "activeresource 2.3.2" => "rails-git",
                                          "activesupport 2.3.2" => nil,
                                          "rails 2.3.2" => "rails-git",
                                          "rake 10.0.2" => nil)
        end
      end
    end

    context "when a top-level gem has an indirect dependency" do
      before do
        build_repo gem_repo2 do
          build_gem "depends_on_rack", "1.0.1" do |s|
            s.add_dependency "rack"
          end
        end

        build_repo gem_repo3 do
          build_gem "unrelated_gem", "1.0.0"
        end

        gemfile <<-G
          source "file://#{gem_repo2}"

          gem "depends_on_rack"

          source "file://#{gem_repo3}" do
            gem "unrelated_gem"
          end
        G
      end

      context "and the dependency is only in the top-level source" do
        before do
          update_repo gem_repo2 do
            build_gem "rack", "1.0.0"
          end
        end

        it "installs all gems without warning" do
          bundle :install
          expect(out).not_to include("Warning")
          expect(err).not_to include("Warning")
          should_be_installed("depends_on_rack 1.0.1", "rack 1.0.0", "unrelated_gem 1.0.0")
        end
      end

      context "and the dependency is only in a pinned source" do
        before do
          update_repo gem_repo3 do
            build_gem "rack", "1.0.0" do |s|
              s.write "lib/rack.rb", "RACK = 'FAIL'"
            end
          end
        end

        it "does not find the dependency" do
          bundle :install, :expect_err => true
          expect(err).to include strip_whitespace(<<-E).strip
            Could not find gem 'rack', which is required by gem 'depends_on_rack', in any of the relevant sources:
              rubygems repository file:#{gem_repo2}/ or installed locally
          E
        end
      end

      context "and the dependency is in both the top-level and a pinned source" do
        before do
          update_repo gem_repo2 do
            build_gem "rack", "1.0.0"
          end

          update_repo gem_repo3 do
            build_gem "rack", "1.0.0" do |s|
              s.write "lib/rack.rb", "RACK = 'FAIL'"
            end
          end
        end

        it "installs the dependency from the top-level source without warning" do
          bundle :install, :expect_err => true
          expect(out).not_to include("Warning")
          expect(err).not_to include("Warning")
          should_be_installed("depends_on_rack 1.0.1", "rack 1.0.0", "unrelated_gem 1.0.0")
        end
      end
    end

    context "with a gem that is only found in the wrong source" do
      before do
        build_repo gem_repo3 do
          build_gem "not_in_repo1", "1.0.0"
        end

        gemfile <<-G
          source "file://#{gem_repo3}"
          gem "not_in_repo1", :source => "file://#{gem_repo1}"
        G
      end

      it "does not install the gem" do
        bundle :install
        expect(err).to include("Could not find gem 'not_in_repo1'")
      end
    end

    context "with an existing lockfile" do
      before do
        system_gems "rack-0.9.1", "rack-1.0.0"

        lockfile <<-L
          GEM
            remote: file:#{gem_repo1}
            remote: file:#{gem_repo3}
            specs:
              rack (0.9.1)

          PLATFORMS
            ruby

          DEPENDENCIES
            rack!
        L

        gemfile <<-G
          source "file://#{gem_repo1}"
          source "file://#{gem_repo3}" do
            gem 'rack'
          end
        G
      end

      # Reproduction of https://github.com/bundler/bundler/issues/3298
      it "does not unlock the installed gem on exec" do
        should_be_installed("rack 0.9.1")
      end
    end

    context "with a path gem in the same Gemfile" do
      before do
        build_lib "foo"

        gemfile <<-G
          gem "rack", :source => "file://#{gem_repo1}"
          gem "foo", :path => "#{lib_path("foo-1.0")}"
        G
      end

      it "does not unlock the non-path gem after install" do
        bundle :install

        bundle %(exec ruby -e 'puts "OK"')

        expect(out).to include("OK")
        expect(exitstatus).to eq(0) if exitstatus
      end
    end
  end

  context "when an older version of the same gem also ships with Ruby" do
    before do
      system_gems "rack-0.9.1"

      gemfile <<-G
        source "file://#{gem_repo1}"
        gem "rack" # shoud come from repo1!
      G
    end

    it "installs the gems without any warning" do
      bundle :install
      expect(out).not_to include("Warning")
      should_be_installed("rack 1.0.0")
    end
  end

  context "when a single source contains multiple locked gems" do
    before do
      # 1. With these gems,
      build_repo4 do
        build_gem "foo", "0.1"
        build_gem "bar", "0.1"
      end

      # 2. Installing this gemfile will produce...
      gemfile <<-G
        source 'file://#{gem_repo1}'
        gem 'rack'
        gem 'foo', '~> 0.1', :source => 'file://#{gem_repo4}'
        gem 'bar', '~> 0.1', :source => 'file://#{gem_repo4}'
      G

      # 3. this lockfile.
      lockfile <<-L
        GEM
          remote: file:/Users/andre/src/bundler/bundler/tmp/gems/remote1/
          remote: file:/Users/andre/src/bundler/bundler/tmp/gems/remote4/
          specs:
            bar (0.1)
            foo (0.1)
            rack (1.0.0)

        PLATFORMS
          ruby

        DEPENDENCIES
          bar (~> 0.1)!
          foo (~> 0.1)!
          rack
      L

      bundle "config path ../gems/system"
      bundle "install"

      # 4. Then we add some new versions...
      update_repo4 do
        build_gem "foo", "0.2"
        build_gem "bar", "0.3"
      end
    end
  end
end
