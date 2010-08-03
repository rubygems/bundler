require "spec_helper"

describe "bundle install with deprecated features" do
  before :each do
    in_app_root
  end

  %w( only except disable_system_gems disable_rubygems
      clear_sources bundle_path bin_path ).each do |deprecated|

    it "reports that #{deprecated} is deprecated" do
      gemfile <<-G
        #{deprecated}
      G

      bundle :install
      out.should =~ /'#{deprecated}' has been removed/
      out.should =~ /See the README for more information/
    end

  end


  %w( require_as vendored_at only except ).each do |deprecated|

    it "reports that :#{deprecated} is deprecated" do
      gemfile <<-G
        gem "rack", :#{deprecated} => true
      G

      bundle :install
      out.should =~ /Please replace :#{deprecated}|The :#{deprecated} option is no longer supported/
    end

  end

  it "reports that --production is deprecated" do
    gemfile %{gem "rack"}
    bundle "install --production"
    out.should =~ /--production option is deprecated/
  end

end
