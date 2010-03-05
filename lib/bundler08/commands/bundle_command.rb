class Gem::Commands::BundleCommand < Gem::Command

  def initialize
    super('bundle', 'Create a gem bundle based on your Gemfile', {:manifest => nil, :update => false})

    add_option('-i', '--init',"Create a Gemfile") do
      options[:init] = true
    end

    add_option('-m', '--manifest MANIFEST', "Specify the path to the manifest file") do |manifest, options|
      options[:manifest] = manifest
    end

    add_option('-u', '--update', "Force a remote check for newer gems") do
      options[:update] = true
    end

    add_option('--cached', "Only use cached gems when expanding the bundle") do
      options[:cached] = true
    end

    add_option('--cache GEM', "Specify a path to a .gem file to add to the bundled gem cache") do |gem, options|
      options[:cache] = gem
    end

    add_option('--prune-cache', "Removes all .gem files that are not a part of the bundle from the cache") do
      options[:prune] = true
    end

    add_option('--list', "List all gems that are part of the active bundle") do
      options[:list] = true
    end

    add_option('--list-outdated', "List all outdated gems that are part of the active bundle") do
      options[:list_outdated] = true
    end

    add_option('-b', '--build-options OPTION_FILE', "Specify a path to a yml file with build options for binary gems") do |option_file, options|
      if File.exist?(option_file)
        require 'yaml'
        options[:build_options] = YAML.load_file(option_file)
      end
    end

    add_option('--only ENV', "Only expand the given environment.  To specify multiple environments, use --only multiple times.") do |env, options|
      options[:only] ||= []
      options[:only] << env
    end
  end

  def usage
    "#{program_name}"
  end

  def description # :nodoc:
    <<-EOF
Bundle stuff
    EOF
  end

  def execute
    # Prevent the bundler from getting required unless it is actually being used
    require 'bundler08'
    if options[:cache]
      Bundler::CLI.run(:cache, options)
    elsif options[:prune]
      Bundler::CLI.run(:prune, options)
    elsif options[:list]
      Bundler::CLI.run(:list, options)
    elsif options[:list_outdated]
      Bundler::CLI.run(:list_outdated, options)
    elsif options[:init]
      if File.exists?("Gemfile")
        Bundler.logger.error "The Gemfile already exists"
      else
        FileUtils.cp File.expand_path("../../templates/Gemfile", __FILE__), "Gemfile"
        Bundler.logger.info "Initialized Gemfile in #{Dir.pwd}"
      end
    else
      Bundler::CLI.run(:bundle, options)
    end
  end

end
