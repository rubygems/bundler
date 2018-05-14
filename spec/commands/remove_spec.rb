# frozen_string_literal: true

RSpec.describe "bundle remove" do
  context "when no gems are specified" do
    it "throws error" do
      gemfile <<-G
          source "file://#{gem_repo1}"
        G

      bundle "remove"

      expect(out).to include("Please specify gems to remove.")
    end
  end

  context "when --install flag is specified" do
    it "removes gems from .bundle" do
      gemfile <<-G
          source "file://#{gem_repo1}"

          gem "rack"
        G

      bundle! "remove rack --install"

      expect(out).to include("rack was removed.")
      expect(the_bundle).to_not include_gems "rack"
    end
  end

  describe "basic gemfile" do
    context "remove single gem from gemfile" do
      it "when gem is present in gemfile" do
        gemfile <<-G
          source "file://#{gem_repo1}"

          gem "rack"
        G

        bundle! "remove rack"

        expect(out).to include("rack was removed.")
        gemfile_should_be <<-G
          source "file://#{gem_repo1}"
        G
      end

      it "when gem is not present in gemfile" do
        gemfile <<-G
          source "file://#{gem_repo1}"
        G

        bundle "remove rack"

        expect(out).to include("You cannot remove a gem which not specified in Gemfile.")
        expect(out).to include("`rack` is not specified in Gemfile so not removed.")
      end
    end

    context "remove mutiple gems from gemfile" do
      it "when all gems are present in gemfile" do
        gemfile <<-G
          source "file://#{gem_repo1}"

          gem "rack"
          gem "rails"
        G

        bundle! "remove rack rails"

        expect(out).to include("rack was removed.")
        expect(out).to include("rails was removed.")
        gemfile_should_be <<-G
          source "file://#{gem_repo1}"
        G
      end

      it "when a gem is not present in gemfile" do
        gemfile <<-G
          source "file://#{gem_repo1}"

          gem "rails"
        G

        bundle "remove rack rails"
        expect(out).to include("You cannot remove a gem which not specified in Gemfile.")
        expect(out).to include("`rack` is not specified in Gemfile so not removed.")
      end
    end
  end

  describe "with groups" do
    context "with inline groups" do
      it "removes the gem" do
        gemfile <<-G
          source "file://#{gem_repo1}"

          gem "rack", :group => [:dev]
        G

        bundle! "remove rack"

        expect(out).to include("rack was removed.")
        gemfile_should_be <<-G
          source "file://#{gem_repo1}"
        G
      end
    end

    context "removes empty block on removal of all gems from it" do
      it "when single group block with gem is present" do
        gemfile <<-G
          source "file://#{gem_repo1}"

          group :test do
            gem "rspec"
          end
        G

        bundle! "remove rspec"

        expect(out).to include("rspec was removed.")
        gemfile_should_be <<-G
          source "file://#{gem_repo1}"
        G
      end

      it "when any other empty block is also present" do
        gemfile <<-G
          source "file://#{gem_repo1}"

          group :test do
            gem "rspec"
          end

          group :dev do
          end
        G

        bundle! "remove rspec"

        expect(out).to include("rspec was removed.")
        gemfile_should_be <<-G
          source "file://#{gem_repo1}"
        G
      end
    end

    context "when gem belongs to mutiple groups" do
      it "when gems assigned to multiple groups" do
        gemfile <<-G
          source "file://#{gem_repo1}"

          group :test, :serioustest do
            gem "rspec"
          end
        G

        bundle! "remove rspec"

        expect(out).to include("rspec was removed.")
        gemfile_should_be <<-G
          source "file://#{gem_repo1}"
        G
      end

      it "gem is present in mutiple groups" do
        gemfile <<-G
          source "file://#{gem_repo1}"

          group :one do
            gem "rspec"
          end

          group :two do
            gem "rspec"
          end
        G

        bundle! "remove rspec"

        expect(out).to include("rspec was removed.")
        gemfile_should_be <<-G
          source "file://#{gem_repo1}"
        G
      end
    end

    context "nested group blocks" do
      it "when all the groups will be empty after removal" do
        gemfile <<-G
          source "file://#{gem_repo1}"

          group :test do
            group :serioustest do
              gem "rspec"
            end
          end
        G

        bundle! "remove rspec"

        expect(out).to include("rspec was removed.")
        gemfile_should_be <<-G
          source "file://#{gem_repo1}"
        G
      end

      it "when outer group will not be empty after removal" do
        install_gemfile <<-G
          source "file://#{gem_repo1}"

          group :test do
            gem "rack-test"

            group :serioustest do
              gem "rspec"
            end
          end
        G

        bundle! "remove rspec"

        expect(out).to include("rspec was removed.")
        gemfile_should_be <<-G
          source "file://#{gem_repo1}"

          group :test do
            gem "rack-test"

          end
        G
      end

      it "when inner group will not be empty after removal" do
        install_gemfile <<-G
          source "file://#{gem_repo1}"

          group :test do
            group :serioustest do
              gem "rspec"
              gem "rack-test"
            end
          end
        G

        bundle! "remove rspec"

        expect(out).to include("rspec was removed.")
        gemfile_should_be <<-G
          source "file://#{gem_repo1}"

          group :test do
            group :serioustest do
              gem "rack-test"
            end
          end
        G
      end
    end
  end

  describe "arbitrary gemfile" do
    context "when mutiple gems are present in same line" do
      it "shows warning for gems not removed" do
        install_gemfile <<-G
          source "file://#{gem_repo1}"
          gem "rack"; gem "rails"
        G

        bundle! "remove rails"

        expect(out).to include("rails could not be removed.")
        gemfile_should_be <<-G
          source "file://#{gem_repo1}"
          gem "rack"; gem "rails"
        G
      end
    end

    context "when some gems could not be removed" do
      it "shows warning for gems not removed and success for those removed" do
        install_gemfile <<-G
          source "file://#{gem_repo1}"
          gem"rack"
          gem"rspec"
          gem "rails"
          gem "minitest"
        G

        bundle! "remove rails rack rspec minitest"

        expect(out).to include("rails was removed.")
        expect(out).to include("minitest was removed.")
        expect(out).to include("rack, rspec could not be removed.")
        gemfile_should_be <<-G
          source "file://#{gem_repo1}"
          gem"rack"
          gem"rspec"
        G
      end
    end
  end

  context "with sources" do
    before do
      build_repo gem_repo3 do
        build_gem "rspec"
      end
    end

    it "removes gems and empty source blocks" do
      gemfile <<-G
        source "file://#{gem_repo1}"

        gem "rack"

        source "file://#{gem_repo3}" do
          gem "rspec"
        end
      G

      bundle! "install"

      bundle! "remove rspec"

      expect(out).to include("rspec was removed.")
      gemfile_should_be <<-G
        source "file://#{gem_repo1}"

        gem "rack"
      G
    end
  end

  context "with eval_gemfile" do
    it "removes gems" do
      create_file "Gemfile-other", <<-G
        gem "rack"
      G

      install_gemfile <<-G
        source "file://#{gem_repo1}"

        eval_gemfile "Gemfile-other"
      G

      bundle! "remove rack"

      expect(bundled_app("Gemfile-other").read).to_not include("gem \"rack\"")
      expect(out).to include("rack was removed.")
    end
  end

  context "with install_if" do
    it "should remove gems inside blocks and empty blocks" do
      install_gemfile <<-G
        source "file://#{gem_repo1}"

        install_if(lambda { false }) do
          gem "rack"
        end
      G

      bundle! "remove rack"

      expect(out).to include("rack was removed.")
      gemfile_should_be <<-G
        source "file://#{gem_repo1}"
      G
    end
  end

  context "with env" do
    it "should remove gems inside blocks and empty blocks" do
      install_gemfile <<-G
        source "file://#{gem_repo1}"

        env "BUNDLER_TEST" do
          gem "rack"
        end
      G

      bundle! "remove rack"

      expect(out).to include("rack was removed.")
      gemfile_should_be <<-G
        source "file://#{gem_repo1}"
      G
    end
  end

  context "with gemspec" do
    it "should not remove the gem" do
      build_lib("foo", :path => tmp.join("foo")) do |s|
        s.write("foo.gemspec", "")
        s.add_dependency "rack"
      end

      install_gemfile(<<-G)
        source "file://#{gem_repo1}"
        gemspec :path => '#{tmp.join("foo")}', :name => 'foo'
      G

      bundle! "remove foo"

      expect(out).to include("foo could not be removed.")
    end
  end
end
