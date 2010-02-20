combined = [File.basename($0)] + ARGV
gem_i  = combined.index("gem")
exec_i = combined.index("exec")

if gem_i && exec_i && gem_i < exec_i
  exec = ARGV.index("exec")
  $command = ARGV[(exec + 1)..-1]
  ARGV.replace ARGV[0..exec]
end

class Gem::Commands::ExecCommand < Gem::Command

  def initialize
    super('exec', 'Run a command in context of a gem bundle', {:manifest => nil})

    add_option('-m', '--manifest MANIFEST', "Specify the path to the manifest file") do |manifest, options|
      options[:manifest] = manifest
    end
  end

  def usage
    "#{program_name} COMMAND"
  end

  def arguments # :nodoc:
    "COMMAND  command to run in context of the gem bundle"
  end

  def description # :nodoc:
    <<-EOF.gsub('      ', '')
      Run in context of a bundle
    EOF
  end

  def execute
    # Prevent the bundler from getting required unless it is actually being used
    require 'bundler08'
    Bundler::CLI.run(:exec, options)
  end

end