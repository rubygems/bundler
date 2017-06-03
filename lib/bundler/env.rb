# frozen_string_literal: true
require "bundler/rubygems_integration"
require "bundler/source/git/git_proxy"

module Bundler
  class Env
    def self.write(io)
      io.write report
    end

    def self.report(options = {})
      print_gemfile = options.delete(:print_gemfile) { true }
      print_gemspecs = options.delete(:print_gemspecs) { true }

      out = String.new("## Environment\n\n```\n")
      env = environment
      environment_ljust = env.map {|(k, _v)| k.to_s.length }.max
      env.each do |(k, v)|
        out << "#{k.to_s.ljust(environment_ljust)}  #{v}\n"
      end
      out << "```\n"

      unless Bundler.settings.all.empty?
        out << "\n## Bundler settings\n\n```\n"
        Bundler.settings.all.each do |setting|
          out << setting << "\n"
          Bundler.settings.pretty_values_for(setting).each do |line|
            out << "  " << line << "\n"
          end
        end
        out << "```\n"
      end

      return out unless SharedHelpers.in_bundle?

      if print_gemfile
        out << "\n## Gemfile\n"
        out << "\n### #{Bundler.default_gemfile.relative_path_from(SharedHelpers.pwd)}\n\n"
        out << "```ruby\n" << read_file(Bundler.default_gemfile).chomp << "\n```\n"

        out << "\n### #{Bundler.default_lockfile.relative_path_from(SharedHelpers.pwd)}\n\n"
        out << "```\n" << read_file(Bundler.default_lockfile).chomp << "\n```\n"
      end

      if print_gemspecs
        dsl = Dsl.new.tap {|d| d.eval_gemfile(Bundler.default_gemfile) }
        out << "\n## Gemspecs\n" unless dsl.gemspecs.empty?
        dsl.gemspecs.each do |gs|
          out << "\n### #{File.basename(gs.loaded_from)}"
          out << "\n\n```ruby\n" << read_file(gs.loaded_from).chomp << "\n```\n"
        end
      end

      out
    end

    def self.read_file(filename)
      File.read(filename.to_s).strip
    rescue Errno::ENOENT
      "<No #{filename} found>"
    rescue => e
      "#{e.class}: #{e.message}"
    end

    def self.ruby_version
      str = String.new("#{RUBY_VERSION}")
      if RUBY_VERSION < "1.9"
        str << " (#{RUBY_RELEASE_DATE}"
        str << " patchlevel #{RUBY_PATCHLEVEL}" if defined? RUBY_PATCHLEVEL
        str << ") [#{RUBY_PLATFORM}]"
      else
        str << "p#{RUBY_PATCHLEVEL}" if defined? RUBY_PATCHLEVEL
        str << " (#{RUBY_RELEASE_DATE} revision #{RUBY_REVISION}) [#{RUBY_PLATFORM}]"
      end
    end

    def self.git_version
      Bundler::Source::Git::GitProxy.new(nil, nil, nil).full_version
    rescue Bundler::Source::Git::GitNotInstalledError
      "not installed"
    end

    def self.environment
      out = []

      out << ["Bundler", Bundler::VERSION]
      out << ["RubyGems", Gem::VERSION]
      out << ["Ruby", ruby_version]
      out << ["GEM_HOME", ENV["GEM_HOME"]] unless ENV["GEM_HOME"].nil? || ENV["GEM_HOME"].empty?
      out << ["GEM_PATH", ENV["GEM_PATH"]] unless ENV["GEM_PATH"].nil? || ENV["GEM_PATH"].empty?
      out << ["RVM", ENV["rvm_version"]] if ENV["rvm_version"]
      out << ["Git", git_version]
      out << ["Platform", Gem::Platform.local]
      out << ["OpenSSL", OpenSSL::OPENSSL_VERSION] if defined?(OpenSSL::OPENSSL_VERSION)
      %w[rubygems-bundler open_gem].each do |name|
        specs = Bundler.rubygems.find_name(name)
        out << [name, "(#{specs.map(&:version).join(",")})"] unless specs.empty?
      end
      if (exe = caller.last.split(":").first) && exe =~ %r{(exe|bin)/bundler?\z}
        shebang = File.read(exe).lines.first
        shebang.sub!(/^#!\s*/, "")
        unless shebang.start_with?(Gem.ruby, "/usr/bin/env ruby")
          out << ["Gem.ruby", Gem.ruby]
          out << ["bundle #!", shebang]
        end
      end

      out
    end

    private_class_method :read_file, :ruby_version, :git_version
  end
end
