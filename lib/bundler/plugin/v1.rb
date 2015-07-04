module Bundler
  module Plugin
    module V1
      autoload :Command,   "bundler/plugin/v1/command"
      autoload :Source,    "bundler/plugin/v1/source"
      autoload :Lifecycle, "bundler/plugin/v1/lifecycle"
      autoload :Plugin,    "bundler/plugin/v1/plugin"
      autoload :Manager,   "bundler/plugin/v1/manager"
    end
  end
end
