# frozen_string_literal: true
require "support/helpers"
require "support/path"

module Spec
  CommandExecution = Struct.new(:command, :working_directory, :exitstatus, :stdout, :stderr) do
    include RSpec::Matchers::Composable

    def to_s
      "$ #{command.strip}"
    end
    alias_method :inspect, :to_s

    def stdboth
      @stdboth ||= [stderr, stdout].join("\n").strip
    end

    def bundler_err
      if Bundler::VERSION.start_with?("1.")
        stdout
      else
        stderr
      end
    end

    def to_s_verbose
      [
        to_s,
        stdout,
        stderr,
        exitstatus ? "# $? => #{exitstatus}" : "",
      ].reject(&:empty?).join("\n")
    end

    def success?
      return true unless exitstatus
      exitstatus == 0
    end
  end
end
