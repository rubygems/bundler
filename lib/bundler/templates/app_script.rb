<%= shebang bin_file_name %>
require "<%= path.join("environments", "default") %>"
load "<%= path.join("gems", @spec.full_name, @spec.bindir, bin_file_name) %>"