require 'thread'

module Bundler
  class WorkerPool
    POISON = Object.new

    class JobException < StandardError
      attr_reader :exception
      def initialize(exn)
        @exception = exn
      end
    end

    # Creates a worker pool of specified size
    #
    # @param size [Integer] Size of pool
    # @param func [Proc] The job to be run by each pool worker
    def initialize(size, job)
      @request_queue = Queue.new
      @response_queue = Queue.new

      @threads = size.times.map do |i|
        Thread.start do
          loop do
            obj = @request_queue.deq
            break if obj.equal? POISON
            begin
              @response_queue.enq job.call(obj, i)
            rescue Exception => e
              @response_queue.enq(JobException.new(e))
            end
          end
        end
      end
    end

    # Enque a request to be executed in the worker pool
    #
    # @param obj [String] mostly it is name of spec that should be downloaded
    def enq(obj)
      @request_queue.enq obj
    end

    # Retrieves results of job function being executed in worker pool
    def deq
      result = @response_queue.deq
      raise result.exception if result.is_a?(JobException)
      result
    end

    # Stop the worker threads by sending a poison object down the request queue
    # so as worker threads after retrieving it, shut themselves down
    def stop
      @threads.each { @request_queue.enq POISON }
      @threads.each { |thread| thread.join }
    end

  end
end
