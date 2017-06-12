# frozen_string_literal: true

RSpec.describe "bundle version" do
  context "with -v" do
    it "outputs the version" do
      bundle! "-v"
      expect(out).to eq("Bundler version #{Bundler::VERSION}")
    end
  end

  context "with --version" do
    it "outputs the version" do
      bundle! "--version"
      expect(out).to eq("Bundler version #{Bundler::VERSION}")
    end
  end

  context "with version" do
    it "outputs the version with build metadata" do
      date = Bundler::BUILD_METADATA[:built_at]
      git_sha = Bundler::BUILD_METADATA[:git_sha]
      bundle! "version"
      expect(out).to eq("Bundler version #{Bundler::VERSION} (#{date} commit #{git_sha})")
    end
  end
end
