module Bundler
  class Init 
    def self.define_init!(opts)
      if File.exist?("Gemfile")
        Bundler.ui.error "Gemfile already exists at #{Dir.pwd}/Gemfile"
        exit 1
      end

      if opts[:gemspec]
        gemspec = File.expand_path(opts[:gemspec])
        unless File.exist?(gemspec)
          Bundler.ui.error "Gem specification #{gemspec} doesn't exist"
          exit 1
        end
        spec = Gem::Specification.load(gemspec)
        puts "Writing new Gemfile to #{Dir.pwd}/Gemfile"
        File.open('Gemfile', 'wb') do |file|
          file << "# Generated from #{gemspec}\n"
          file << spec.to_gemfile
        end
      else
        puts "Writing new Gemfile to #{Dir.pwd}/Gemfile"
        FileUtils.cp(File.expand_path('../../templates/Gemfile', __FILE__), 'Gemfile')
      end
    end
  end
end
