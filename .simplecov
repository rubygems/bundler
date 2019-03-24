# frozen_string_literal: true

command_name = if ENV["BUNDLER_REALWORLD_TESTS"]
  "realworld"
elsif ENV["BUNDLER_SUDO_TESTS"]
  "sudo"
else
  "regular_specs"
end

SimpleCov.command_name command_name

SimpleCov.start do
  add_filter "/bin/"
  add_filter "/lib/bundler/vendor/"
  add_filter "/man/"
  add_filter "/pkg/"
  add_filter "/spec/"
  add_filter "/tmp/"
end
