require "optparse"

module Bundler
  class CLI
    def self.run(args = ARGV)
      new(args).run
    end

    def initialize(args)
      @args = args
    end

    def run
      parser.parse!(@args)

      manifest_file = Bundler::ManifestFile.load(@manifest)
      if @args.empty?
        manifest_file.install
      else
        manifest_file.setup_environment
        exec(*@args)
      end
    rescue DefaultManifestNotFound => e
      Bundler.logger.error "Could not find a Gemfile to use"
      exit 2
    rescue InvalidEnvironmentName => e
      Bundler.logger.error "Gemfile error: #{e.message}"
      exit
    rescue InvalidRepository => e
      Bundler.logger.error e.message
      exit
    rescue VersionConflict => e
      Bundler.logger.error e.message
      exit
    end

    def parser
      @parser ||= OptionParser.new do |op|
        op.banner = "Usage: gem_bundler [OPTIONS] [PATH]"

        op.on("-m", "--manifest MANIFEST") do |manifest|
          @manifest = Pathname.new(manifest)
        end

        op.on_tail("-h", "--help", "Show this message") do
          puts op
          exit
        end
      end
    end
  end
end
