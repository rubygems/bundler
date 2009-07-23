module Bundler
  def self.rubygems_required
    <% spec_files.each do |name, path| %>
    Gem.loaded_specs["<%= name %>"] = eval(File.read("<%= path %>"))
    <% end %>
  end
end

<% if @rubygems == :optional %>
$LOAD_PATH.unshift File.expand_path(File.dirname(__FILE__))
<% end %>
<% load_paths.each do |load_path| %>
$LOAD_PATH.unshift "<%= load_path %>"
<% end %>
<% if @rubygems == :require %>
require "rubygems"
<% elsif @rubygems == :disable %>
$" << "rubygems.rb"
<% end %>