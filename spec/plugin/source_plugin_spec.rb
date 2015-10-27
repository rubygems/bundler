require "spec_helper"

describe "bundler source plugin" do
  before :each do
    build_gem "bundler-foo", :to_system => true do |s|
      main = <<-EOF
class BundlerCustomSource < Bundler.plugin("1")
  name "Custom source plugin"
  source "foo" do
    require "source"
    Source
  end
end
      EOF
      source = <<-EOF
require "bundler/index"
class Source < Bundler.plugin("1", :source)
  attr_reader :options
  def initialize (options)
    @options = options
  end

  def specs(*)
    index = Bundler::Index.new
    index << Gem::Specification.new do |s|
      s.name = "bar"
      s.source   = self
      s.version  = Gem::Version.new("1.0")
      s.platform = Gem::Platform::RUBY
      s.summary  = "Fake gemspec for bar"
      s.authors  = ["no one"]
    end
    index
  end

  def install(spec, force = false)
    ["Using "+version_message(spec)+" from foo", nil]
  end
end
      EOF

      s.write("lib/bundler-foo.rb", main)
      s.write("lib/source.rb", source)
    end
  end

  it "installs the plugin" do
    install_gemfile <<-G
      plugin "foo"
    G
    expect(out).to include("Setting up plugins...")
    expect(out).to include("Using bundler-foo 1.0")
  end

  it "uses the source" do
    install_gemfile <<-G
      plugin "foo"
      gem "bar", :foo => "baz"
    G
    expect(out).to include("Using bar 1.0 from foo")
  end
end
