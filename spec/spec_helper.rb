$:.unshift File.expand_path('..', __FILE__)
$:.unshift File.expand_path('../../lib', __FILE__)

require 'fileutils'
require 'rubygems'
require 'bundler'
require 'rspec'

Dir["#{File.expand_path('../support', __FILE__)}/*.rb"].each do |file|
  require file
end

$debug    = false
$show_err = true

Spec::Rubygems.setup
FileUtils.rm_rf(Spec::Path.gem_repo1)
ENV['RUBYOPT'] = "-I#{Spec::Path.root}/spec/support/rubygems_hax"

RSpec.configure do |config|
  config.include Spec::Builders
  config.include Spec::Helpers
  config.include Spec::Indexes
  config.include Spec::Matchers
  config.include Spec::Path
  config.include Spec::Rubygems
  config.include Spec::Platforms
  config.include Spec::Sudo

  original_wd       = Dir.pwd
  original_path     = ENV['PATH']
  original_gem_home = ENV['GEM_HOME']

  def pending_jruby_shebang_fix
    pending "JRuby executables do not have a proper shebang" if RUBY_PLATFORM == "java"
  end

  def check(*args)
    # suppresses ruby warnings about "useless use of == in void context"
    # e.g. check foo.should == bar
  end

  config.before :all do
    @__current_dir__ = Dir.pwd
    build_repo1
  end

  config.before :each do
    reset!
    system_gems []
    chdir bundled_app.to_s
  end

  config.after :each do
    # clean up open pipes
    @in_p.close  if @in_p
    @out_p.close if @out_p
    @err_p.close if @err_p
    Dir.chdir(original_wd)
    # Reset ENV
    env.clear
  end

  Thread.abort_on_exception = true

  class Queue
    def initialize
      @pipes = []
    end

    def push(pipe)
      @pipes << pipe
    end

    def read
      Thread.new do
        loop do
          begin
            sleep 0.1 until @pipes[0]
            pipe = @pipes.shift
            break if pipe == :EOF

            puts "READING: #{pipe.inspect}"
            while line = pipe.gets
              puts line
            end

            pipe.close
          rescue Exception => e
            puts "OMGOMGOMG ERRORZ: #{e.message} - #{e.class}"
            puts e.backtrace
            exit!
          end
        end
      end
    end
  end

  module ForkingRunner
    @queue = Queue.new

    def self.queue
      @queue
    end

    def self.pipe
      Thread.current[:pipe]
    end

    def self.pipe=(pipe)
      Thread.current[:pipe] = pipe
    end

    def run(reporter)
      if ForkingRunner.pipe
        super
      else
        read, write = IO.pipe
        ForkingRunner.queue.push read
        t = Thread.new do
          ForkingRunner.pipe = write

          def reporter.output
            ForkingRunner.pipe || super
          end

          puts "PUSHING A PIPE YO"
          super
          puts "CLOSING A PIPE YO"
          write.close
        end
      end
    end
  end

  # config.extend ForkingRunner
end

# module RSpec::Core::CommandLine::ExampleGroups
#   alias old_run_examples run_examples
# 
#   def run_examples(reporter)
#     t = ForkingRunner.queue.read
#     old_run_examples(reporter)
#     ForkingRunner.queue.push :EOF
# 
#     t.join
#   end
# end
