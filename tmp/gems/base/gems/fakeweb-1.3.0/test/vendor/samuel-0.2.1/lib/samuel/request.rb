module Samuel
  class Request

    attr_accessor :response

    def initialize(http, request, proc)
      @http, @request, @proc = http, request, proc
    end

    def perform_and_log!
      # If an exception is raised in the Benchmark block, it'll interrupt the
      # benchmark. Instead, use an inner block to record it as the "response"
      # for raising after the benchmark (and logging) is done.
      @seconds = Benchmark.realtime do
        begin; @response = @proc.call; rescue Exception => @response; end
      end
      Samuel.logger.add(log_level, log_message)
      raise @response if @response.is_a?(Exception)
    end

    private

    def log_message
      bold      = "\e[1m"
      blue      = "\e[34m"
      underline = "\e[4m"
      reset     = "\e[0m"
      "  #{bold}#{blue}#{underline}#{label} request (#{milliseconds}ms) " +
      "#{response_summary}#{reset}  #{method} #{uri}"
    end

    def milliseconds
      (@seconds * 1000).round
    end

    def uri
      "#{scheme}://#{@http.address}#{port_if_not_default}#{filtered_path}"
    end

    def filtered_path
      path_without_query, query = @request.path.split("?")
      if query
        patterns = [Samuel.config[:filtered_params]].flatten
        patterns.map { |pattern|
          pattern_for_regex = Regexp.escape(pattern.to_s)
          [/([^&]*#{pattern_for_regex}[^&=]*)=(?:[^&]+)/, '\1=[FILTERED]']
        }.each { |filter| query.gsub!(*filter) }
        "#{path_without_query}?#{query}"
      else
        @request.path
      end
    end

    def scheme
      @http.use_ssl? ? "https" : "http"
    end

    def port_if_not_default
      ssl, port = @http.use_ssl?, @http.port
      if (!ssl && port == 80) || (ssl && port == 443)
        ""
      else
        ":#{port}"
      end
    end

    def method
      @request.method.to_s.upcase
    end

    def label
      return Samuel.config[:label] if Samuel.config[:label]

      pair = Samuel.config[:labels].detect { |domain, label| @http.address.include?(domain) }
      pair[1] if pair
    end

    def response_summary
      if response.is_a?(Exception)
        response.class
      else
        "[#{response.code} #{response.message}]"
      end
    end

    def log_level
      error_classes = [Exception, Net::HTTPClientError, Net::HTTPServerError]
      if error_classes.any? { |klass| response.is_a?(klass) }
        level = Logger::WARN
      else
        level = Logger::INFO
      end
    end

  end
end
