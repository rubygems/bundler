require 'bundler/source/git/git_proxy'

module Bundler
  class Env

    def write(io)
      io.write(report)
    end

    def report(options = {})
      print_gemfile = options.delete(:print_gemfile)

      out = "Bundler #{Bundler::VERSION}\n"

      out << "Rubygems #{Gem::VERSION}\n"

      out << "rvm #{ENV['rvm_version']}\n" if ENV['rvm_version']

      out << "Git #{git_information}"

      out << "GEM_HOME #{ENV['GEM_HOME']}\n"

      out << "GEM_PATH #{ENV['GEM_PATH']}\n" unless ENV['GEM_PATH'] == ENV['GEM_HOME']

      out << `command git --version 2>&1`.strip << "\n"

      %w(rubygems-bundler open_gem).each do |name|
        if Gem::Specification.respond_to?(:find_all)
          specs = Gem::Specification.find_all{|s| s.name == name }
          out << "#{name} (#{specs.map(&:version).join(',')})\n" unless specs.empty?
        end
      end

      out << "\nBundler settings\n" unless Bundler.settings.all.empty?
      Bundler.settings.all.each do |setting|
        out << "  #{setting}\n"
        Bundler.settings.pretty_values_for(setting).each do |line|
          out << "    " << line << "\n"
        end
      end

      if print_gemfile
        out << "\n\n" << "Gemfile\n"
        out << read_file("Gemfile") << "\n"

        out << "\n\n" << "Gemfile.lock\n"
        out << read_file("Gemfile.lock") << "\n"
      end

      out
    end

  private

    def read_file(filename)
      File.read(filename).strip
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
