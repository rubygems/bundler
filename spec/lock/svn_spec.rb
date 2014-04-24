require "spec_helper"

describe "bundle lock with svn gems" do
  before :each do
    build_svn "foo"

    install_gemfile <<-G
      gem 'foo', :svn => "file://#{lib_path('foo-1.0')}"
    G
  end

  it "doesn't break right after running lock" do
    should_be_installed "foo 1.0.0"
  end

  it "locks a svn source to the current ref" do
    update_svn "foo" do |s|
      s.write "lib/foo.rb", "puts :CACHE"
    end
    bundle :install

    run <<-RUBY
      require 'foo'
    RUBY

    expect(out).not_to eq("CACHE")
  end

  it "provides correct #full_gem_path" do
    run <<-RUBY
      puts Bundler.rubygems.find_name('foo').first.full_gem_path
    RUBY
    expect(out).to eq(bundle("show foo"))
  end
end
