require "spec_helper"

describe "Bundler.with_clean_env" do

  it "should reset and restore the environment" do
    gemfile <<-G
      source "file://#{gem_repo1}"
      gem "rack"
    G

    bundle "install --path vendor"
    puts out

    env["GEM_HOME"] = "omg"

    run <<-RUBY
      puts ENV['GEM_HOME']

      Bundler.with_clean_env do
        puts `echo $GEM_HOME`.strip
      end

      puts ENV['GEM_HOME'].strip
    RUBY

    home = File.expand_path(vendored_gems)
    out.should == "#{home}\nomg\n#{home}"
  end

end
