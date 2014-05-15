require 'thread'

require "bundler/parallel_workers/worker"

module Bundler
  module ParallelWorkers
    autoload :UnixWorker, "bundler/parallel_workers/unix_worker"
    autoload :ThreadWorker, "bundler/parallel_workers/thread_worker"

    def self.worker_pool(size, job)
      ThreadWorker.new(size, job)
    end
  end
end
