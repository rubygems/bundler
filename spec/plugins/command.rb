# frozen_string_literal: true
require "spec_helper"

describe "command plugins" do
  it "executes without arguments" do
    build_repo2 do
      build_plugin "command-mah" do |s|
        s.write "plugin.rb", <<-RUBY
          module Mah
            class Plugin < Bundler::Plugin::Api
              command "mahcommand" # declares the command

              def exec(command, args)
                puts "MahHello"
              end
            end
          end
        RUBY
      end
    end

    bundle "plugin install command-mah --source file://#{gem_repo2}"
    expect(out).to include("Installed plugin command-mah")

    bundle "mahcommand"
    expect(out).to eq("MahHello")
  end

  it "accepts the arguments" do
    build_repo2 do
      build_plugin "the-echoer" do |s|
        s.write "plugin.rb", <<-RUBY
          module Resonance
            class Echoer
              # Another method to declare the command
              Bundler::Plugin::Api.command "echo", self

              def exec(command, args)
                puts "You gave me \#{args.join(", ")}"
              end
            end
          end
        RUBY
      end
    end

    bundle "plugin install the-echoer --source file://#{gem_repo2}"
    expect(out).to include("Installed plugin the-echoer")

    bundle "echo tacos tofu lasange", "no-color" => false
    expect(out).to eq("You gave me tacos, tofu, lasange")
  end
end
