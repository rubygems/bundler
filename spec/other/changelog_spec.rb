require "spec_helper"

def make_changelog(fname)
  File.open File.join(default_bundle_path('gems', 'rails-2.3.2'), fname), "w" do |f|
    f.puts "This is the contents of the changelog file"
  end
end

describe "bundle changelog" do
  before :each do
    install_gemfile <<-G
      source "file://#{gem_repo1}"
      gem "rails"
    G
  end

  describe "searches for different changelog files" do

    [ "CHANGELOG.md", "history.rdoc", "changes.txt", "changeLog" ].each do |changelog|

      it "prints the file CHANGELOG.md" do
        File.open File.join(default_bundle_path('gems', 'rails-2.3.2'), changelog), "w" do |f|
          f.puts "This is the contents of the changelog file"
        end

        bundle "changelog rails"
        out.should eq("This is the contents of the changelog file")
      end

    end
  end

  it "complains if a changelog wasn't found" do
    bundle "changelog rails"
    out.should match(/No Changelog found for 'rails'/i)
  end

  it "complains if gem not in bundle" do
    bundle "changelog missing"
    out.should match(/could not find gem 'missing'/i)
  end

end
