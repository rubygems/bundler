# frozen_string_literal: true
module Spec
  if RUBY_VERSION > "1.9"
    require "open3"
    Open3 = ::Open3
  else
    module Open3
      def popen3(*cmd, &block)
        opts = {}
        opts = cmd.pop if cmd.last.is_a?(Hash)

        in_r, in_w = IO.pipe
        opts[:in] = in_r
        in_w.sync = true

        out_r, out_w = IO.pipe
        opts[:out] = out_w

        err_r, err_w = IO.pipe
        opts[:err] = err_w

        child_io = [in_r, out_w, err_w]
        parent_io = [in_w, out_r, err_r]

        pid = fork do
          STDIN.reopen(in_r)
          STDOUT.reopen(out_w)
          STDERR.reopen(err_w)
          exec(*cmd)
        end

        wait_thr = Process.detach(pid)
        child_io.each(&:close)
        result = parent_io + [wait_thr]
        if block_given?
          begin
            return yield(*result)
          ensure
            parent_io.each {|io| io.close unless io.closed? }
            wait_thr.join
          end
        end
        result
      end
      module_function :popen3
    end
  end
end
