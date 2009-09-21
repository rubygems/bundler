module Bundler
  class Repository
    class Directory
      attr_reader :path, :bindir

      def initialize(path, bindir)
        @path   = path
        @bindir = bindir

        FileUtils.mkdir_p(path.to_s)
      end

      def download_path_for
        @path.join("dirs")
      end

      # Checks whether a gem is installed
      def expand(options)
        # raise NotImplementedError
      end
    end
  end
end