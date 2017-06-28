# frozen_string_literal: true
require 'pry'

RSpec.describe "bundle permissions" do
  before do
    gemfile <<-G
      source "file://#{gem_repo1}"
      gem "rails"
    G
  end

  context "/.bundle directory" do
    context "when it's owned by the user executing `bundle install`" do
      it "returns a permissions satisfied message" do
        bundle :permissions

        expect(out).to eq("The Gemfile's permissions are satisfied")
      end
    end

    context "when it's possible to read/write to by the user executing `bundle install`" do
      it "raises a permissions warning message" do
        FileUtils.chmod(0000, default_bundle_path.to_s)

        bundle :permissions

        expect(out).to include("WARN")
      end
    end

    context "when it's not possible to read/write to by the user executing `bundle install`" do
      it "raises a permissions error message" do
        FileUtils.chmod(0000, default_bundle_path.to_s)

        bundle :permissions

        expect(out).to include("ERROR")
      end
    end
  end
end
