require 'rubygems/command_manager'
require 'bundler/commands/bundle_command'
require 'bundler/commands/exec_command'

Gem::CommandManager.instance.register_command :bundle
Gem::CommandManager.instance.register_command :exec