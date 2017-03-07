# frozen_string_literal: true
module Bundler
  class CLI::Config2
    attr_reader :options, :scope, :thor, :command, :name, :value
    attr_accessor :args

    # bundle config set name value
    # bundle config unset name
    def initialize(options, args, thor)
      @args = args
      arg0 = args.shift.downcase
      if arg0 == "set" || arg0 == "unset"
        @command = arg0.to_sym
        @name = args.shift
        @value = args.shift
      else
        @name = arg0
      end

      @options = options
      @scope = options["global"] ? :global : :local
    end

    def run
      set if command == :set
      unset if command == :unset
    end

    def set
      scope == :global ? Bundler.settings.set_global(name, value) : Bundler.settings.set_local(name, value)
    end

    def unset
      scope == :global ? Bundler.settings.set_global(name, nil) : Bundler.settings.set_local(name, nil)
    end
  end
end
