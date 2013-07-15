module Bundler
  module ParallelWorkers
    class UnixWorker < Worker

      class JobHandler < Struct.new(:pid, :io_r, :io_w)
        def work(obj)
          Marshal.dump obj, io_w
          Marshal.load io_r
        rescue IOError
          nil
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
              begin
                Marshal.dump WrappedException.new(e), child_write
              rescue Errno::EPIPE
                nil
              end
            ensure
              child_read.close
              child_write.close
            end
          end

          child_read.close
          child_write.close
          JobHandler.new pid, parent_read, parent_write
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
          Process.kill :INT, worker.pid
        end
        @workers.each do |worker|
          Process.waitpid worker.pid
        end
      end
    end
  end
end
