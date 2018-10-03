# frozen_string_literal: true

module Bundler
  module UI
    autoload :Logger,  "bundler/ui/logger"
    autoload :RGProxy, "bundler/ui/rg_proxy"
    autoload :Shell,   "bundler/ui/shell"
    autoload :Silent,  "bundler/ui/silent"
  end
end
