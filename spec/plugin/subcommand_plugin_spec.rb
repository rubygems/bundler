require "spec_helper"

describe "bundler subcommand plugin" do
  before :each do
    build_gem "bundler-foo", :to_system => true do |s|
      main = <<-EOF
class BundlerCustomSubcommand < Bundler.plugin("1")
  name "Custom subcommand plugin"
  command "foo" do
    require "command"
    Command
  end
end
      EOF
      command = <<-EOF
class Command < Bundler.plugin("1", :command)

  def initialize
    @command_name = "Foo [OPTIONS]"
    @command_short_description = "This will print foo + argument"
    @command_long_description =
    <<-D
          This will print hi + argument
    D
  end

  def run(options, args)
    puts "hi "+args[0]
  end
end
      EOF

      s.write("lib/bundler-foo.rb", main)
      s.write("lib/command.rb", command)
    end
    bundle "plugin install foo"
  end

  it "uses the plugin" do
    bundle "foo bar"
    expect(out).to include("hi bar")
  end

  it "uninstalls the subcommand plugin" do
    bundle "plugin uninstall foo"
    expect(out).to include("Bundler plugin 'foo' has been successfully uninstalled")
  end
end
