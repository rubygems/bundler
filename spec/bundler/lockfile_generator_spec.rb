# frozen_string_literal: true

RSpec.describe "Bundler::LockfileGenerator" do
  context "Gemfile contains private credentials in source", :bundler => ">= 2" do
    it "filters out private token for lockfile" do
      gemfile <<-G
source "https://my-secret-token:x-oauth-basic@github.com/foo/bar.git"
      G
      bundle "install"
      expect("gems.locked").not_to have_file_content "my-secret-token"
    end

    it "filters out private password for lockfile" do
      gemfile <<-G
source "https://username:my-secret-password@github.com/foo/bar.git"
      G
      bundle "install"
      expect("gems.locked").not_to have_file_content "my-secret-password"
    end
  end
end
