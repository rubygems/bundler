class IO
  def read_available_bytes(chunk_size = 1024, select_timeout = 5)
    buffer = []

    while self.class.select([self], nil, nil, select_timeout)
      begin
        buffer << self.readpartial(chunk_size)
      rescue(EOFError)
        break
      end
    end

    return buffer.join
  end
end