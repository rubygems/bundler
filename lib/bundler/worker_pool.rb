require 'thread'

module Bundler
  class WorkerPool
    POISON = Object.new

    class WrappedException < StandardError
      attr_reader :exception
      def initialize(exn)
        @exception = exn
      end
    end

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

    private

    if WINDOWS
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

      def prepare_threads(size)
      end

      def stop_workers
      end
    else
      class Worker < Struct.new(:pid, :io_r, :io_w)
        def work(obj)
          Marshal.dump obj, io_w
          Marshal.load io_r
        end
      end

      def prepare_workers(size, func)
        @workers = size.times.map do
          child_read, parent_write = IO.pipe
          parent_read, child_write = IO.pipe

          pid = Process.fork do
            begin
              parent_read.close
              parent_write.close

              while !child_read.eof?
                obj = Marshal.load child_read
                Marshal.dump func.call(obj), child_write
              end
            rescue Exception => e
              Marshal.dump WrappedException.new(e), child_write
            ensure
              child_read.close
              child_write.close
            end
          end

          child_read.close
          child_write.close
          Worker.new pid, parent_read, parent_write
        end
      end

      def prepare_threads(size)
        @threads = size.times.map do |i|
          Thread.start do
            worker = @workers[i]
            Thread.current.abort_on_exception = true
            loop do
              obj = @request_queue.deq
              break if obj.equal? POISON
              @response_queue.enq worker.work(obj)
            end
          end
        end
      end

      def stop_workers
        @workers.each do |worker|
          worker.io_r.close
          worker.io_w.close
        end
        @workers.each do |worker|
          Process.waitpid worker.pid
        end
      end
    end

    def stop_threads
      @threads.each do
        @request_queue.enq POISON
      end
      @threads.each do |thread|
        thread.join
      end
    end
  end
end
