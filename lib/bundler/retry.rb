module Bundler
  # General purpose class for retrying code that may fail
  class Retry
    attr_accessor :name, :max_attempts, :current_attempt

    def initialize(name, max_attempts = 1)
      @name            = name
      @max_attempts    = max_attempts
    end

    def attempt(&block)
      @current_attempt = 0
      @failed          = false
      @error           = nil
      while keep_trying? do
        run(&block)
      end
      @result
    end
    alias :attempts :attempt

  private
    def run(&block)
      @failed          = false
      @current_attempt += 1
      @result = block.call
    rescue => e
      fail(e)
    end

    def fail(e)
      @failed = true
      raise e if last_attempt?
      return true unless name
      Bundler.ui.warn "Retrying #{name} due to error (#{current_attempt.next}/#{max_attempts}): #{e.message}"
    end

    def keep_trying?
      return true  if current_attempt.zero?
      return false if last_attempt?
      return true  if @failed
    end

    def last_attempt?
      current_attempt >= max_attempts
    end
  end
end
