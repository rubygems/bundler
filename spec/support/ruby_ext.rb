class IO
  def read_available_bytes(chunk_size = 1024, select_timeout = 5)
    buffer = []

    return "" if closed? || eof?
    # IO.select cannot be used here due to the fact that it
    # just does not work on windows
    while true
      begin
        buffer << self.readpartial(chunk_size)
        sleep 0.1
      rescue(EOFError)
        break
      end
    end

    return buffer.join
  end
end
