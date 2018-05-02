# frozen_string_literal: true

RSpec.describe "bundle remove" do
  describe "basic gemfile" do
    context "remove single gem from gemfile" do
      it "when gem is present in gemfile" do
        gemfile <<-G
          source "file://#{gem_repo1}"

          gem "rack"
        G

        bundle! "remove rack"

        expect(gemfile).to_not include("gem \"rack\"")
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

        bundle! "remove rack rails"

        expect(gemfile).to_not include("gem \"rack\"")
        expect(gemfile).to_not include("gem \"rails\"")
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

          gem "rack", group: [:dev]
        G

        bundle! "remove rack"

        expect(gemfile).to_not include("gem \"rack\"")
        expect(out).to include("rack(>= 0) was removed.")
      end
    end

    context "removes empty block on removal of all gems from it" do
      it "when single group block with gem is present" do
        gemfile <<-G
          source "file://#{gem_repo1}"

          group :test do
            gem "minitest"
          end
        G

        bundle! "remove minitest"

        expect(gemfile).to_not match(/group :test do/)
        expect(gemfile).to_not include("gem \"minitest\"")
        expect(out).to include("minitest(>= 0) was removed.")
      end

      it "when any other empty block is also present" do
        gemfile <<-G
          source "file://#{gem_repo1}"

          group :test do
            gem "minitest"
          end

          group :dev do
          end
        G

        bundle! "remove minitest"

        expect(gemfile).to_not match(/group :test do/)
        expect(gemfile).to_not include("gem \"minitest\"")
        expect(gemfile).to_not match(/group :dev do/)
        expect(out).to include("minitest(>= 0) was removed.")
      end
    end

    context "when gem belongs to mutiple groups" do
      it "when gems assigned to multiple groups" do
        gemfile <<-G
          source "file://#{gem_repo1}"

          group :test, :serioustest do
            gem "minitest"
          end
        G

        expected_gemfile = "source \"file://#{gem_repo1}\"\n"

        bundle! "remove minitest"

        expect(gemfile).to eq(expected_gemfile)
        expect(out).to include("minitest(>= 0) was removed.")
      end

      it "gem is present in mutiple groups" do
        gemfile <<-G
          source "file://#{gem_repo1}"

          group :one do
            gem "minitest"
          end

          group :two do
            gem "minitest"
          end
        G

        expected_gemfile = "source \"file://#{gem_repo1}\"\n\n" \
                        "group :one do\n" \
                        "  group :serioustest do" \
                        "    gem \"minitest-reporters\"\n" \
                        "  end" \
                        "end"

        bundle! "remove minitest"

        expect(gemfile).to eq(expected_gemfile)
        expect(out).to include("minitest(>= 0) was removed.")
      end
    end

    context "nested group blocks" do
      it "case 1" do
        gemfile <<-G
          source "file://#{gem_repo1}"

          group :test do
            group :serioustest do
              gem "minitest"
            end
          end
        G

        expected_gemfile = "source \"file://#{gem_repo1}\"\n"

        bundle! "remove minitest"

        expect(gemfile).to eq(expected_gemfile)
        expect(out).to include("minitest(>= 0) was removed.")
      end

      it "case 2" do
        gemfile <<-G
          source "file://#{gem_repo1}"

          group :test do
            group :serioustest do
              gem "minitest"
            end

            gem "minitest-reporters"
          end
        G

        expected_gemfile = "source \"file://#{gem_repo1}\"\n\n" \
                        "group :test do\n" \
                        "  gem \"minitest-reporters\"\n" \
                        "end"

        bundle! "remove minitest"

        expect(gemfile).to eq(expected_gemfile)
        expect(out).to include("minitest(>= 0) was removed.")
      end

      it "case 3" do
        gemfile <<-G
          source "file://#{gem_repo1}"

          group :test do
            group :serioustest do
              gem "minitest"
              gem "minitest-reporters"
            end
          end
        G

        expected_gemfile = "source \"file://#{gem_repo1}\"\n\n" \
                        "group :test do\n" \
                        "  group :serioustest do" \
                        "    gem \"minitest-reporters\"\n" \
                        "  end" \
                        "end"

        bundle! "remove minitest"

        expect(gemfile).to eq(expected_gemfile)
        expect(out).to include("minitest(>= 0) was removed.")
      end
    end
  end
end
