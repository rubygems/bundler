# frozen_string_literal: true
require "thread"

module Bundler
  class Worker
    POISON = Object.new

    class WrappedException < StandardError
      attr_reader :exception
      def initialize(exn)
        @exception = exn
      end
    end

    # @return [String] the name of the worker
    attr_reader :name

    # Creates a worker pool of specified size
    #
    # @param size [Integer] Size of pool
    # @param name [String] name the name of the worker
    # @param func [Proc] job to run in inside the worker pool
    def initialize(size, name, func)
      @name = name
      @request_queue = Queue.new
      @response_queue = Queue.new
      @func = func
      @threads = Array.new(size) do |i|
        Thread.start { process_queue(i) }.tap do |thread|
          thread.name = "#{name} Worker ##{i}" if thread.respond_to?(:name=)
        end
      end
      trap("INT") { abort_threads }
    end

    # Enqueue a request to be executed in the worker pool
    #
    # @param obj [String] mostly it is name of spec that should be downloaded
    def enq(obj)
      @request_queue.enq obj
    end

    # Retrieves results of job function being executed in worker pool
    def deq
      result = @response_queue.deq
      raise result.exception if result.is_a?(WrappedException)
      result
    end

    def stop
      stop_threads
    end

  private

    def process_queue(i)
      loop do
        obj = @request_queue.deq
        break if obj.equal? POISON
        @response_queue.enq apply_func(obj, i)
      end
    end

    def apply_func(obj, i)
      @func.call(obj, i)
    rescue Exception => e
      WrappedException.new(e)
    end

    # Stop the worker threads by sending a poison object down the request queue
    # so as worker threads after retrieving it, shut themselves down
    def stop_threads
      @threads.each { @request_queue.enq POISON }
      @threads.each(&:join)
    end

    def abort_threads
      @threads.each(&:exit)
      exit 1
    end
  end
end
