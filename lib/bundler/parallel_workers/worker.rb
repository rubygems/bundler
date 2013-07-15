module Bundler
  module ParallelWorkers
    class Worker
      POISON = Object.new

      class WrappedException < StandardError
        attr_reader :exception
        def initialize(exn)
          @exception = exn
        end
      end

      # Creates a worker pool of specified size
      #
      # @param size [Integer] Size of pool
      # @param func [Proc] job to run in inside the worker pool
      def initialize(size, func)
        @request_queue = Queue.new
        @response_queue = Queue.new
        prepare_workers size, func
        prepare_threads size
      end

      def enq(obj)
        @request_queue.enq obj
      end

      def deq
        result = @response_queue.deq
        if WrappedException === result
          raise result.exception
        end
        result
      end

      def stop
        stop_workers
        stop_threads
      end

      def stop_threads
        @threads.each do
          @request_queue.enq POISON
        end
        @threads.each do |thread|
          thread.join
        end
      end

      def prepare_threads(size)
      end

      def stop_workers
      end

    end
  end
end
