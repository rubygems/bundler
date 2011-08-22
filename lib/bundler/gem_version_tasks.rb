$:.unshift File.expand_path('../vendor', __FILE__)
require 'thor'
require 'bundler'

module Bundler
  class GemHelper

    def self.version_tasks(opts = {})
      dir = opts[:dir] || Dir.pwd
      self.new(dir, opts[:name]).version_tasks
    end

    VERSION_ASSIGNMENT_REGEXP = /\A\s*?VERSION\s*?=\s*?['"](.*?)['"]\s*?\z/mx

    def version_tasks
      desc "Handle gem version"
      namespace 'version' do
        desc "Bump major version number"
        task "bump:major" do
          increment :major
        end
        desc "Bump minor version number"
        task "bump:minor" do
          increment :minor
        end
        desc "Bump patch version number"
        task "bump:patch" do
          increment :patch
        end
        desc "write out a specified version (rake version:write[\"x.y.z\"])"
        task "write", :version do |task, args|
          change_version_to(args.version)
        end
      end
    end

    def increment bit_to_increment
      change_version_to incremented_version(bit_to_increment)
    end

    def change_version_to(new_version)
      File.open(version_file, 'w') { |f| f << new_version_file(new_version) }
      puts "New version is now #{new_version}"
    end

    protected

    def incremented_version bit_to_increment
      hash = {}
      hash[:major], hash[:minor], hash[:patch] = version.split('.')
      hash[bit_to_increment] = hash[bit_to_increment].to_i + 1
      "#{hash[:major]}.#{hash[:minor]}.#{hash[:patch]}"
    end

    def new_version_file new_version
      lines_of_version_file.map do |line|
        is_line_with_version_assignment?(line) ? %Q{  VERSION = "#{new_version}"\n} : line
      end.join
    end

    def lines_of_version_file
      @content_of_version_file ||= File.readlines(version_file)
    end

    def version_file
      file_array = Dir['*/**/version.rb']
      raise_too_many_files_found if file_array.size > 1
      file_array.first
    end

    def is_line_with_version_assignment? line
      !!(line[VERSION_ASSIGNMENT_REGEXP])
    end

    def raise_too_many_files_found
      raise ArgumentError, "There are two files called version.rb and I do not know which one to use. Override the version_file method in your Rakefile and provide the correct path."
    end

  end
end
