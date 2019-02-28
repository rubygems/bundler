# frozen_string_literal: true

directory ".git/hooks"

file ".git/hooks/pre-commit" => [__FILE__] do |t|
  File.open(t.name, "w") {|f| f << <<-SH }
#!/bin/sh

set -e

.git/hooks/run-ruby bin/rubocop
.git/hooks/run-ruby bin/rspec spec/quality_spec.rb
  SH

  chmod 0o755, t.name, :verbose => false
end

file ".git/hooks/pre-push" => [__FILE__] do |_t|
  Dir.chdir(".git/hooks") do
    safe_ln "pre-commit", "pre-push", :verbose => false
  end
end

file ".git/hooks/run-ruby" => [__FILE__] do |t|
  File.open(t.name, "w") {|f| f << <<-SH }
#!/bin/bash

ruby="ruby"
command -v chruby-exec >/dev/null 2>&1 && [[ -f ~/.ruby-version ]] && ruby="chruby-exec $(cat ~/.ruby-version) --"
ruby $@
  SH

  chmod 0o755, t.name, :verbose => false
end

task :git_hooks => Rake::Task.tasks.select {|t| t.name.start_with?(".git/hooks") }
