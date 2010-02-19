require 'rubygems/command_manager'
require 'bundler08/commands/bundle_command'
require 'bundler08/commands/exec_command'

Gem::CommandManager.instance.register_command :bundle
Gem::CommandManager.instance.register_command :exec