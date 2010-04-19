module Bundler
  module Flex
    module Environment
      def write_yml_lock
        File.open("#{root}/Gemfile.lock", 'w') do |f|
          f.puts details
        end
      end

      def details
        output = ""

        pinned_sources = dependencies.map {|d| d.source }
        all_sources    = @definition.sources.map {|s| s }

        specified_sources = all_sources - pinned_sources

        unless specified_sources.empty?
          output << "sources:\n"

          specified_sources.each do |source|
            output << "  #{source.to_lock}\n"
          end
          output << "\n"
        end

        unless @definition.dependencies.empty?
          output << "dependencies:\n"
          @definition.dependencies.each do |dependency|
            output << dependency.to_lock
          end
          output << "\n"
        end

        output << "specs:\n"
        specs.sort_by {|s| s.name }.each do |spec|
          output << spec.to_lock
        end

        output
      end
    end

    class Installer < Bundler::Installer
      include Environment

      def run(*)
        super
        lock
      end
    end

    class Runtime < Bundler::Runtime
      include Environment
    end
  end
end