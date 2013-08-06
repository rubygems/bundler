# SafeCatch provides a mechanism to safely deepen the stack, performing
# stack-unrolling similar to catch/throw, but using Fiber or Thread to avoid
# deepening the stack too quickly.
#
# The API is the same as that of catch/throw: SafeCatch#safe_catch takes a "tag"
# to be rescued when some code deeper in the process raises it. If the catch
# block completes successfully, that value is returned. If the tag is "thrown"
# by safe_throw, the tag's value is returned. Other exceptions propagate out as
# normal.
#
# The implementation, however, uses fibers or threads along with raise/rescue to
# handle "deepening" the stack and unrolling it. On implementations where Fiber
# is available, it will be used. If Fiber is not available, Thread will be used.
# If neither of these classes are available, Proc will be used, effectively
# deepening the stack for each recursion as in normal catch/throw.
#
# In order to avoid causing a new issue of creating too many fibers or threads,
# especially on implementations where fibers are actually backed by native
# threads, the "safe" recursion mechanism is only used every 20 recursions.
# Based on experiments with JRuby (which seems to suffer the most from
# excessively deep stacks), this appears to be a sufficient granularity to
# prevent stack overflow without spinning up excessive numbers of fibers or
# threads. This value can be adjusted with the BUNDLER_SAFE_RECURSE_EVERY env
# var; setting it to zero effectively disables safe recursion.

require 'bundler/current_ruby'

module Bundler
  module SafeCatch
    def safe_catch(tag, &block)
      if Bundler.current_ruby.jruby?
        Internal.catch(tag, &block)
      else
        catch(tag, &block)
      end
    end

    def safe_throw(tag, value = nil)
      if Bundler.current_ruby.jruby?
        Internal.throw(tag, value)
      else
        throw(tag, value)
      end
    end

    module Internal
      SAFE_RECURSE_EVERY = (ENV['BUNDLER_SAFE_RECURSE_EVERY'] || 20).to_i

      SAFE_RECURSE_CLASS, SAFE_RECURSE_START = case
      when defined?(Fiber)
        [Fiber, :resume]
      when defined?(Thread)
        [Thread, :join]
      else
        [Proc, :call]
      end

      @recurse_count = 0

      def self.catch(tag, &block)
        @recurse_count += 1
        if SAFE_RECURSE_EVERY >= 0 && @recurse_count % SAFE_RECURSE_EVERY == 0
          SAFE_RECURSE_CLASS.new(&block).send(SAFE_RECURSE_START)
        else
          block.call
        end
      rescue Result.matcher(tag)
        $!.value
      end

      def self.throw(tag, value = nil)
        raise Result.new(tag, value)
      end

      class Result < StopIteration
        def initialize(tag, value)
          @tag = tag
          @value = value
        end

        attr_reader :tag, :value

        # The Matcher class is never instantiated; it is dup'ed and used as a
        # rescue-clause argument to match Result exceptions based on their tags.
        module Matcher
          class << self
            attr_accessor :tag

            def ===(other)
              other.respond_to? :tag and @tag.equal? other.tag
            end
          end
        end

        def self.matcher(tag)
          matcher = Matcher.dup
          matcher.tag = tag
          matcher
        end
      end
    end
  end
end
