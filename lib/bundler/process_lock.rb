# frozen_string_literal: true

module Bundler
  class ProcessLock
    def self.lock(bundle_path = Bundler.bundle_path)
      lock_file_path = File.join(bundle_path, "bundler.lock")

      File.open(lock_file_path, "w") do |f|
        f.flock(File::LOCK_EX)

        yield
      end
    rescue Errno::ENOLCK # NFS
      raise if Thread.main != Thread.current

      yield
    ensure
      File.delete(lock_file_path) if File.exist?(lock_file_path)
    end
  end
end
