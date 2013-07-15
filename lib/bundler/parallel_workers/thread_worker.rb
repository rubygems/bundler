module Bundler
  module ParallelWorkers
    class ThreadWorker < Worker
      def prepare_workers(size, func)
        @threads = size.times.map do |i|
          Thread.start do
            Thread.current.abort_on_exception = true
            loop do
              obj = @request_queue.deq
              break if obj.equal? POISON
              @response_queue.enq func.call(obj)
            end
          end
        end
      end
    end
  end
end
