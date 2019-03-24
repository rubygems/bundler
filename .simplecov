# frozen_string_literal: true

SimpleCov.start do
  add_filter "/bin/"
  add_filter "/lib/bundler/man/"
  add_filter "/lib/bundler/vendor/"
  add_filter "/man/"
  add_filter "/pkg/"
  add_filter "/spec/"
  add_filter "/tmp/"
end
