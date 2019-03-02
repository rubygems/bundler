# frozen_string_literal: true

module Bundler
  class CLI::Help
    attr_reader :topic, :cli
    def initialize(topic = nil, cli = nil)
      @topic = topic
      @cli = cli
    end

    def run
      case topic
      when "gemfile" then command = "gemfile"
      when nil       then command = "bundle"
      else command = "bundle-#{topic}"
      end

      man_path  = File.expand_path("../../../../man", __FILE__)
      man_pages = Hash[Dir.glob(File.join(man_path, "*")).grep(/.*\.\d*\Z/).collect do |f|
        [File.basename(f, ".*"), f]
      end]

      if man_pages.include?(command)
        if Bundler.which("man") && man_path !~ %r{^file:/.+!/META-INF/jruby.home/.+}
          Kernel.exec "man #{man_pages[command]}"
        else
          puts File.read("#{man_path}/#{File.basename(man_pages[command])}.txt")
        end
      elsif command_path = Bundler.which("bundler-#{topic}")
        Kernel.exec(command_path, "--help")
      else
        cli.help(topic, true)
      end
    end
  end
end
