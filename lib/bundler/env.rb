require 'bundler/rubygems_integration'
require 'bundler/source/git/git_proxy'

module Bundler
  class Env

    def write(io)
      io.write report(:print_gemfile => true)
    end

    def report(options = {})
      print_gemfile = options.delete(:print_gemfile)

      out = "Environment\n\n"
      out << "    Bundler   #{Bundler::VERSION}\n"
      out << "    Rubygems  #{Gem::VERSION}\n"
      out << "    Ruby      #{RUBY_VERSION}"
      out << "p#{RUBY_PATCHLEVEL}" if defined? RUBY_PATCHLEVEL
      out << " (#{RUBY_RELEASE_DATE} revision #{RUBY_REVISION}) [#{RUBY_PLATFORM}]\n"
      out << "    GEM_HOME  #{ENV['GEM_HOME']}\n" unless ENV['GEM_HOME'].nil? || ENV['GEM_HOME'].empty?
      out << "    GEM_PATH  #{ENV['GEM_PATH']}\n" unless ENV['GEM_PATH'] == ENV['GEM_HOME']
      out << "    RVM       #{ENV['rvm_version']}\n" if ENV['rvm_version']
      out << "    Git       #{git_information}\n"
      %w(rubygems-bundler open_gem).each do |name|
        specs = Bundler.rubygems.find_name(name)
        out << "    #{name} (#{specs.map(&:version).join(',')})\n" unless specs.empty?
      end

      out << "\nBundler settings\n\n" unless Bundler.settings.all.empty?
      Bundler.settings.all.each do |setting|
        out << "    " << setting << "\n"
        Bundler.settings.pretty_values_for(setting).each do |line|
          out << "      " << line << "\n"
        end
      end

      if print_gemfile
        out << "\nGemfile\n\n"
        out << "    " << read_file(Bundler.default_gemfile).gsub(/\n/, "\n    ") << "\n"

        out << "\n" << "Gemfile.lock\n\n"
        out << "    " << read_file(Bundler.default_lockfile).gsub(/\n/, "\n    ") << "\n"
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

    def git_information
      Bundler::Source::Git::GitProxy.new(nil, nil, nil).version
    rescue Bundler::Source::Git::GitNotInstalledError
      "not installed"
    end

  end
end
