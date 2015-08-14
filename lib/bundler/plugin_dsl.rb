require "bundler/dsl"
module Bundler
  class PluginDsl
    def self.evaluate(gemfile, lockfile, unlock)
      builder = new
      builder.eval_gemfile_for_plugins(gemfile)
      builder.to_plugin_definition(lockfile, unlock)
    end

    def initialize
      @dsl = Dsl.new
      methods = Dsl.instance_methods(false)
      methods.delete(:plugin)

      self.class.instance_eval do
        methods.each do |method|
          define_method(method) do |*|
            # Empty method. So that it ignores the rest of the Gemfile
          end
        end
      end
    end

    def eval_gemfile_for_plugins(gemfile)
      contents ||= Bundler.read_file(gemfile.to_s)
      instance_eval(contents, gemfile.to_s, 1)
    rescue Exception => e
      message = "There was an error parsing `#{File.basename gemfile.to_s}`: #{e.message}"
      raise Dsl::DSLError.new(message, gemfile, e.backtrace, contents)
    end

    def plugin(name, *args)
      @dsl.gem("bundler-#{name}", *args)
    end

    def to_plugin_definition(lockfile, unlock)
      if @dsl.dependencies.count > 0
        @dsl.to_definition(lockfile, unlock)
      else
        nil
      end
    end
  end
end
