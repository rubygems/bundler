# frozen_string_literal: true

namespace :bundler_2 do
  task :install do
    ENV["BUNDLER_SPEC_SUB_VERSION"] = "2.0.0.dev"
    Rake::Task["override_version"].invoke
    Rake::Task["install"].invoke
    sh("git", "checkout", "--", "lib/bundler/version.rb")
  end
end
