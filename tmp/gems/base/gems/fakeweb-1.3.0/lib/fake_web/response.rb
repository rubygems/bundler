module FakeWeb
  module Response #:nodoc:

    def read_body(*args, &block)
      yield @body if block_given?
      @body
    end

  end
end