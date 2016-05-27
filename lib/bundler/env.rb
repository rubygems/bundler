# frozen_string_literal: true
require "bundler/rubygems_integration"
require "bundler/source/git/git_proxy"

module Bundler
  class Env
    def write(io)
      io.write report(:print_gemfile => true, :print_gemspecs => true)
    end

    def report(options = {})
      print_gemfile = options.delete(:print_gemfile)
      print_gemspecs = options.delete(:print_gemspecs)

      out = String.new("Environment\n\n")
      out << "    Bundler   #{Bundler::VERSION}\n"
      out << "    Rubygems  #{Gem::VERSION}\n"
      out << "    Ruby      #{ruby_version}"
      out << "    GEM_HOME  #{ENV["GEM_HOME"]}\n" unless ENV["GEM_HOME"].nil? || ENV["GEM_HOME"].empty?
      out << "    GEM_PATH  #{ENV["GEM_PATH"]}\n" unless ENV["GEM_PATH"] == ENV["GEM_HOME"]
      out << "    RVM       #{ENV["rvm_version"]}\n" if ENV["rvm_version"]
      out << "    Git       #{git_version}\n"
      out << "    OpenSSL   #{OpenSSL::OPENSSL_VERSION}\n"
      %w(rubygems-bundler open_gem).each do |name|
        specs = Bundler.rubygems.find_name(name)
        out << "    #{name} (#{specs.map(&:version).join(",")})\n" unless specs.empty?
      end

      out << "\nBundler settings\n\n" unless Bundler.settings.all.empty?
      Bundler.settings.all.each do |setting|
        out << "    " << setting << "\n"
        Bundler.settings.pretty_values_for(setting).each do |line|
          out << "      " << line << "\n"
        end
      end

      if print_gemfile
        out << "\n#{Bundler.default_gemfile.relative_path_from(SharedHelpers.pwd)}\n\n"
        out << "    " << read_file(Bundler.default_gemfile).gsub(/\n/, "\n    ") << "\n"

        out << "\n#{Bundler.default_lockfile.relative_path_from(SharedHelpers.pwd)}\n\n"
        out << "    " << read_file(Bundler.default_lockfile).gsub(/\n/, "\n    ") << "\n"
      end

      if print_gemspecs
        dsl = Dsl.new.tap {|d| d.eval_gemfile(Bundler.default_gemfile) }
        dsl.gemspecs.each do |gs|
          out << "\n#{Pathname.new(gs).basename}"
          out << "\n\n    " << read_file(gs).gsub(/\n/, "\n    ") << "\n"
        end
      end

      out
    end

  private

    def read_file(filename)
      File.read(filename.to_s).strip
    rescue Errno::ENOENT
      "<No #{filename} found>"
    rescue => e
      "#{e.class}: #{e.message}"
    end

    def ruby_version
      str = String.new("#{RUBY_VERSION}")
      if RUBY_VERSION < "1.9"
        str << " (#{RUBY_RELEASE_DATE}"
        str << " patchlevel #{RUBY_PATCHLEVEL}" if defined? RUBY_PATCHLEVEL
        str << ") [#{RUBY_PLATFORM}]\n"
      else
        str << "p#{RUBY_PATCHLEVEL}" if defined? RUBY_PATCHLEVEL
        str << " (#{RUBY_RELEASE_DATE} revision #{RUBY_REVISION}) [#{RUBY_PLATFORM}]\n"
      end
    end

    def git_version
      Bundler::Source::Git::GitProxy.new(nil, nil, nil).version
    rescue Bundler::Source::Git::GitNotInstalledError
      "not installed"
    end
  end
end
