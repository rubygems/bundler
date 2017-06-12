# frozen_string_literal: true
file "lib/bundler/generated/build_metadata.rb" => [".git/HEAD", ".git/logs/HEAD", __FILE__, :git_hooks] do |t|
  sh "git update-index --assume-unchanged #{t.name}"

  build_metadata = {
    :built_at => BUNDLER_SPEC.date.strftime("%Y-%m-%d"),
    :git_sha => `git rev-parse --short HEAD`.strip,
    :release => Rake::Task["release"].instance_variable_get(:@already_invoked),
  }

  File.open(t.name, "w") {|f| f << <<-RUBY }
# frozen_string_literal: true

module Bundler
  BUILD_METADATA = {
#{build_metadata.sort.map {|k, v| "    #{k.inspect} => #{BUNDLER_SPEC.send(:ruby_code, v)}," }.join("\n")}
  }.freeze
end
  RUBY
end
