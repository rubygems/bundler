# frozen_string_literal: true

def bundler_spec
  Gem::Specification.load("bundler.gemspec")
end

def write_build_metadata(build_metadata)
  build_metadata_file = "lib/bundler/build_metadata.rb"

  ivars = build_metadata.sort.map do |k, v|
    "    @#{k} = #{bundler_spec.send(:ruby_code, v)}"
  end.join("\n")

  contents = File.read(build_metadata_file)
  contents.sub!(/^(\s+# begin ivars).+(^\s+# end ivars)/m, "\\1\n#{ivars}\n\\2")
  File.open(build_metadata_file, "w") {|f| f << contents }
end

task :build_metadata do
  build_metadata = {
    :built_at => bundler_spec.date.utc.strftime("%Y-%m-%d"),
    :git_commit_sha => `git rev-parse --short HEAD`.strip,
    :release => Rake::Task["release"].instance_variable_get(:@already_invoked),
  }

  write_build_metadata(build_metadata)
end

namespace :build_metadata do
  task :clean do
    build_metadata = {
      :release => false,
    }

    write_build_metadata(build_metadata)
  end
end
