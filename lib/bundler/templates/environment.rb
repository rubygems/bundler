<% unless @system_gems %>
ENV["GEM_HOME"] = "<%= @repository.path %>"
ENV["GEM_PATH"] = "<%= @repository.path %>"
<% end %>
ENV["PATH"]     = "<%= @bindir %>:#{ENV["PATH"]}"
ENV["RUBYOPT"]  = "-r#{__FILE__} #{ENV["RUBYOPT"]}"

<% load_paths.each do |load_path| %>
$LOAD_PATH.unshift "<%= load_path %>"
<% end %>

<% if @rubygems %>
require "rubygems"

module Bundler

  @bundled_specs = {}
  <% spec_files.each do |name, path| %>
  @bundled_specs["<%= name %>"] = eval(File.read("<%= path %>"))
  @bundled_specs["<%= name %>"].loaded_from = "<%= path %>"
  <% end %>

  def self.add_specs_to_loaded_specs
    Gem.loaded_specs.merge! @bundled_specs
    if Gem.respond_to?(:loaded_stacks)
      @bundled_specs.keys.each { |name| Gem.loaded_stacks[name] = [] }
    end
  end

  def self.add_specs_to_index
    @bundled_specs.each do |name, spec|
      Gem.source_index.add_spec spec
    end
  end

  add_specs_to_loaded_specs
  add_specs_to_index
end

module Gem
  def source_index.refresh!
    super
    Bundler.add_specs_to_index
  end
end

<% else %>

$" << "rubygems.rb"
module Kernel
  def gem(*)
    # Silently ignore calls to gem, since, in theory, everything
    # is activated correctly already.
  end
end

# Define all the Gem errors for gems that reference them.
module Gem
  def self.ruby ; <%= Gem.ruby.inspect %> ; end
  class LoadError < ::LoadError; end
  class Exception < RuntimeError; end
  class CommandLineError < Exception; end
  class DependencyError < Exception; end
  class DependencyRemovalException < Exception; end
  class GemNotInHomeException < Exception ; end
  class DocumentError < Exception; end
  class EndOfYAMLException < Exception; end
  class FilePermissionError < Exception; end
  class FormatException < Exception; end
  class GemNotFoundException < Exception; end
  class InstallError < Exception; end
  class InvalidSpecificationException < Exception; end
  class OperationNotSupportedError < Exception; end
  class RemoteError < Exception; end
  class RemoteInstallationCancelled < Exception; end
  class RemoteInstallationSkipped < Exception; end
  class RemoteSourceException < Exception; end
  class VerificationError < Exception; end
  class SystemExitException < SystemExit; end
end

<% end %>