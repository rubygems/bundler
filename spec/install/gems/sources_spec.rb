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

    context "when the same version of the same gem is in multiple sources" do
      let(:repo3_rack_version) { "1.0.0" }

      before do
        gemfile <<-G
          source "file://#{gem_repo3}"
          source "file://#{gem_repo1}"
          gem "rack-obama"
          gem "rack"
        G
      end

      it "warns about ambiguous gems, but installs anyway, prioritizing sources last to first" do
        bundle :install

        expect(out).to include("Warning: the gem 'rack' was found in multiple sources.")
        expect(out).to include("Installed from: file:#{gem_repo1}")
        should_be_installed("rack-obama 1.0.0", "rack 1.0.0")
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

      it "warns about ambiguous gems, but installs anyway" do
        bundle :install

        expect(out).to include("Warning: the gem 'rack' was found in multiple sources.")
        expect(out).to include("Installed from: file:#{gem_repo1}")
        should_be_installed("rack-obama 1.0.0", "rack 1.0.0")
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
        end

        gemfile <<-G
          source "file://#{gem_repo3}"
          source "file://#{gem_repo1}" do
            gem "rack"
          end
          gem "rack-obama" # shoud come from repo3!
        G
      end

      it "installs the gems without any warning" do
        bundle :install
        expect(out).not_to include("Warning")
        should_be_installed("rack-obama 1.0.0", "rack 1.0.0")
      end

      it "can cache and deploy" do
        bundle :package

        expect(bundled_app("vendor/cache/rack-1.0.0.gem")).to exist
        expect(bundled_app("vendor/cache/rack-obama-1.0.gem")).to exist

        bundle "install --deployment", :exitstatus => true

        expect(exitstatus).to eq(0)
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
        end

        gemfile <<-G
          source "file://#{gem_repo3}"
          gem "rack-obama" # should come from repo3!
          gem "rack", :source => "file://#{gem_repo1}"
        G
      end

      it "installs the gems without any warning" do
        bundle :install
        expect(out).not_to include("Warning")
        should_be_installed("rack-obama 1.0.0", "rack 1.0.0")
      end
    end

    context "with an indirect dependency" do
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

          it "installs from the other source and warns about ambiguous gems" do
            bundle :install
            expect(out).to include("Warning: the gem 'rack' was found in multiple sources.")
            expect(out).to include("Installed from: file:#{gem_repo2}")
            should_be_installed("depends_on_rack 1.0.1", "rack 1.0.0")
          end
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
        expect(out).to include("Could not find gem 'not_in_repo1 (>= 0) ruby'")
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
end
