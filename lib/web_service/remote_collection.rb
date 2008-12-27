module WebService
  class RemoteCollection
    ARGUMENT_LAYOUT_FOR_REQUEST = [ [Integer, /^[^\/]/],  # ID
                                    [Symbol,  /^\//],     # Action
                                     Hash ].freeze        # Body
    
    # http://github.com/thoughtbot/suspenders/tree/master/config/initializers/errors.rb
    HTTP_ERRORS = [ EOFError,
                    Errno::EINVAL,
                    Errno::ECONNRESET,
                    Net::ProtocolError,
                    Net::HTTPBadResponse,
                    Net::HTTPHeaderSyntaxError ].freeze
    
    attr_reader :resource_class
    attr_reader :nesting
    
    include ResponseHandling
    
    def initialize(resource_details, nesting=[])
      @resource_class, @nesting = resource_details, nesting
    end
    
    def request(method, *args)
      id, action, body = recognize(ARGUMENT_LAYOUT_FOR_REQUEST, *args)
      
      url = build_url_for(id, action)
      content_type, body = perform_adjustments_for_body!(body, method, url)
      request = instantiate_request_for(method, url)
      request.content_type = content_type if content_type
      WebService.logger.info do
        "#{method.to_s.upcase} #{url.obfuscate}#{" (#{body.length} bytes)" if body}"
      end
      response, elapsed = handle_connection_errors do
        benchmark do
          open_http_connection_to(url) do |conn|
            conn.request(request, body).extend ResponseDataUnserialization
          end
        end
      end
      WebService.logger.info do
        status = "=> %d %s"  % [response.code, response.message]
        length = "(%.2f KB)" % [response.content_length / 1024.0] if response.content_length
        time   = "[%d ms]"   % [elapsed * 1000]
        [status, length, time].compact.join(' ')
      end
      handle_response(response)
    end
    
    def with_nesting(further_nesting)
      self.class.new(resource_class, nesting + further_nesting)
    end
    
  private
    
    # Handle the body differently depending on the request method.
    def build_url_for(id, action)
      if resource_class.singleton
        raise ArgumentError, "singleton resources do not require an ID parameter" if id
      else
        id ||= implicit_id if respond_to?(:implicit_id)
      end
      
      url = ensure_url_copy(resource_class.site)
      segments = [url.path]
      nesting.each do |res_name, id_for_association|
        segments << res_name.to_s.pluralize
        raise "attribute `#{res_name}_id' is missing" unless id_for_association
        segments << id_for_association
      end
      segments << (resource_class.singleton ? resource_class.element_name : resource_class.element_name.pluralize)
      segments << (CGI.escape(id.to_s) if id) << action
      url.path = segments.compact.join('/').squeeze('/')
      return url
    end
    
    def instantiate_request_for(method, url)
      request = Net::HTTP.const_get(method.to_s.capitalize).new([url.path, url.query].compact.join('?'))
      request.basic_auth(*resource_class.credentials) if resource_class.credentials
      request['Accept'] = ["application/json", "application/xml"]
      return request
    end
    
    def perform_adjustments_for_body!(body, method, url)
      case method
      when :post, :put
        ["application/json", body.to_json]
      else
        url.query = body.to_query if body.respond_to?(:to_query) && body.method(:to_query).arity <= 0
        [nil, nil]
      end
    end
    
    def open_http_connection_to(url)
      http = Net::HTTP.new(url.host, url.port)
      http.open_timeout = http.read_timeout = 30
      http.use_ssl = url.kind_of?(URI::HTTPS)
      http.verify_mode = OpenSSL::SSL::VERIFY_NONE if http.use_ssl
      http.start do |conn|
        yield conn
      end
    end
    
    def handle_connection_errors
      yield
    rescue Timeout::Error
      raise TimeoutError.new($!.message)
    rescue *HTTP_ERRORS
      raise ConnectionError.new(nil, $!.message)
    end
    
  private # utilities
    
    def recognize(patterns, *objects)
      patterns.map do |pattern|
        if pos = objects.index { |object| case object; when *pattern; true; end }
          objects.delete_at(pos)
        end
      end
    end
    
    def benchmark
      result = nil
      elapsed = Benchmark.realtime do
        result = yield
      end
      return result, elapsed
    end
  
    def ensure_url_copy(url)
      url = url.url if url.respond_to?(:url)
      url.kind_of?(URI) ? url.dup : URI.parse(url)
    end
  
    module ResponseDataUnserialization
      def data
        return @data if defined? @data
        @data = parse_data
      end
      
    private
    
      def parse_data
        case content_type
        when /json/
          ActiveSupport::JSON.decode(body)
        when /xml/
          Hash.from_xml(body)
        else
          body.blank? ? nil : body
        end
      end
    end
  end
end
