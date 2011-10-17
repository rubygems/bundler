require "spec_helper"

describe "bundle readme" do
  before :each do
    install_gemfile <<-G
      source "file://#{gem_repo1}"
      gem "rails"
    G
  end

  describe "searches for different readme files" do

    [ "README", "README.txt", "ReadMe.MARKDOWN", "readme" ].each do |readme|

      it "prints the file README" do
        File.open File.join(default_bundle_path('gems', 'rails-2.3.2'), readme), "w" do |f|
          f.puts "This is the contents of the readme file"
        end

        bundle "readme rails"
        out.should eq("This is the contents of the readme file")
      end

    end
  end

  it "complains if a readme wasn't found" do
    bundle "readme rails"
    out.should match(/No README found for 'rails'/i)
  end

  it "complains if gem not in bundle" do
    bundle "readme missing"
    out.should match(/could not find gem 'missing'/i)
  end

end
