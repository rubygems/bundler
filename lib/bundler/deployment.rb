module Bundler
  class Deployment
    def self.install_bundle(context)
      bundle_cmd     = context.fetch(:bundle_cmd, "bundle")
      bundle_flags   = context.fetch(:bundle_flags, "--deployment --quiet")
      bundle_dir     = context.fetch(:bundle_dir, File.join(context.fetch(:shared_path), 'bundle'))
      bundle_gemfile = context.fetch(:bundle_gemfile, "Gemfile")
      bundle_without = [*context.fetch(:bundle_without, [:development, :test])].compact
      
      args = ["--gemfile #{File.join(context.fetch(:current_release), bundle_gemfile)}"]
      args << "--path #{bundle_dir}" unless bundle_dir.to_s.empty?
      args << bundle_flags.to_s
      args << "--without #{bundle_without.join(" ")}" unless bundle_without.empty?
      
      context.run "#{bundle_cmd} install #{args.join(' ')}"
    end
  end
end