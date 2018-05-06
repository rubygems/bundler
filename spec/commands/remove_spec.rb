# frozen_string_literal: true

RSpec.describe "bundle remove" do
  describe "basic gemfile" do
    context "remove single gem from gemfile" do
      it "when gem is present in gemfile" do
        gemfile <<-G
          source "file://#{gem_repo1}"

          gem "rack"
        G

        expected_gemfile = "source \"file://#{gem_repo1}\"\n"

        bundle! "remove rack"

        expect(gemfile).to eq(expected_gemfile)
        expect(out).to include("rack(>= 0) was removed.")
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

        expected_gemfile = "source \"file://#{gem_repo1}\"\n"

        bundle! "remove rack rails"

        expect(gemfile).to eq(expected_gemfile)
        expect(out).to include("rack(>= 0) was removed.")
        expect(out).to include("rails(>= 0) was removed.")
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

        expected_gemfile = "source \"file://#{gem_repo1}\"\n"

        bundle! "remove rack"

        expect(gemfile).to eq(expected_gemfile)
        expect(out).to include("rack(>= 0) was removed.")
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

        expected_gemfile = "source \"file://#{gem_repo1}\"\n"

        bundle! "remove rspec"

        expect(gemfile).to eq(expected_gemfile)
        expect(out).to include("rspec(>= 0) was removed.")
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

        expected_gemfile = "source \"file://#{gem_repo1}\"\n"

        bundle! "remove rspec"

        expect(gemfile).to eq(expected_gemfile)
        expect(out).to include("rspec(>= 0) was removed.")
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

        expected_gemfile = "source \"file://#{gem_repo1}\"\n"

        bundle! "remove rspec"

        expect(gemfile).to eq(expected_gemfile)
        expect(out).to include("rspec(>= 0) was removed.")
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

        expected_gemfile = "source \"file://#{gem_repo1}\"\n"

        bundle! "remove rspec"

        expect(gemfile).to eq(expected_gemfile)
        expect(out).to include("rspec(>= 0) was removed.")
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

        expected_gemfile = "source \"file://#{gem_repo1}\"\n"

        bundle! "remove rspec"

        expect(gemfile).to eq(expected_gemfile)
        expect(out).to include("rspec(>= 0) was removed.")
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

        expected_gemfile = "source \"file://#{gem_repo1}\"\n\n" \
                        "group :test do\n" \
                        "  gem \"rack-test\"\n\n" \
                        "end\n"

        bundle! "remove rspec"

        expect(gemfile).to eq(expected_gemfile)
        expect(out).to include("rspec(>= 0) was removed.")
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

        expected_gemfile = "source \"file://#{gem_repo1}\"\n\n" \
                        "group :test do\n" \
                        "  group :serioustest do\n" \
                        "    gem \"rack-test\"\n" \
                        "  end\n" \
                        "end\n"

        bundle! "remove rspec"

        expect(gemfile).to eq(expected_gemfile)
        expect(out).to include("rspec(>= 0) was removed.")
      end
    end
  end
end
