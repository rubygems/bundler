# frozen_string_literal: true

module Bundler
  BUILD_METADATA = {
    :built_at => Time.now.strftime("%Y-%m-%d").freeze,
    :git_sha => Dir.chdir(File.expand_path("..", __FILE__)) { `git rev-parse --short HEAD`.strip }.freeze,
    :release => false,
  }.freeze
end
