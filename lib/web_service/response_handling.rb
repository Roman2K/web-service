# Copyright (c) 2006 David Heinemeier Hansson
# 
# Permission is hereby granted, free of charge, to any person obtaining
# a copy of this software and associated documentation files (the
# "Software"), to deal in the Software without restriction, including
# without limitation the rights to use, copy, modify, merge, publish,
# distribute, sublicense, and/or sell copies of the Software, and to
# permit persons to whom the Software is furnished to do so, subject to
# the following conditions:
# 
# The above copyright notice and this permission notice shall be
# included in all copies or substantial portions of the Software.
# 
# THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND,
# EXPRESS OR IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF
# MERCHANTABILITY, FITNESS FOR A PARTICULAR PURPOSE AND
# NONINFRINGEMENT. IN NO EVENT SHALL THE AUTHORS OR COPYRIGHT HOLDERS BE
# LIABLE FOR ANY CLAIM, DAMAGES OR OTHER LIABILITY, WHETHER IN AN ACTION
# OF CONTRACT, TORT OR OTHERWISE, ARISING FROM, OUT OF OR IN CONNECTION
# WITH THE SOFTWARE OR THE USE OR OTHER DEALINGS IN THE SOFTWARE.

# Extracted from ActiveResource 79f55de9c5e3ff1f8d9e767c5af21ba31be4cfba.
module WebService
  module ResponseHandling
    module Exceptions
      class ConnectionError < StandardError # :nodoc:
        attr_reader :response

        def initialize(response, message = nil)
          @response = response
          @message  = message
        end

        def to_s
          "Failed with #{response.code} #{response.message if response.respond_to?(:message)}"
        end
      end

      # Raised when a Timeout::Error occurs.
      class TimeoutError < ConnectionError
        def initialize(message)
          @message = message
        end
        def to_s; @message ;end
      end

      # 3xx Redirection
      class Redirection < ConnectionError # :nodoc:
        def to_s; response['Location'] ? "#{super} => #{response['Location']}" : super; end
      end

      # 4xx Client Error
      class ClientError < ConnectionError; end # :nodoc:

      # 400 Bad Request
      class BadRequest < ClientError; end # :nodoc

      # 401 Unauthorized
      class UnauthorizedAccess < ClientError; end # :nodoc

      # 403 Forbidden
      class ForbiddenAccess < ClientError; end # :nodoc

      # 404 Not Found
      class ResourceNotFound < ClientError; end # :nodoc:
      
      # 406 Not Acceptable
      class NotAcceptable < ClientError; end # :nodoc:

      # 409 Conflict
      class ResourceConflict < ClientError; end # :nodoc:
    
      # 422 Unprocessable Entity
      class ResourceInvalid < ClientError; end #:nodoc:

      # 5xx Server Error
      class ServerError < ConnectionError; end # :nodoc:

      # 405 Method Not Allowed
      class MethodNotAllowed < ClientError # :nodoc:
        def allowed_methods
          @response['Allow'].split(',').map { |verb| verb.strip.downcase.to_sym }
        end
      end
    end
    include Exceptions
  
    # Fix ConnectionError message.
    ConnectionError.class_eval do
      def to_s
        returning "Failed" do |message|
          message << " with #{response.code}" if response && response.respond_to?(:code) && response.code
          message << " (#{response.message})" if response && response.respond_to?(:message) && !response.message.to_s.strip.empty?
          message << ": #{@message}" if @message
        end
      end
    end
  
  protected
    
    # Handles response and error codes from remote service.
    def handle_response(response)
      case response.code.to_i
        when 301,302
          raise(Redirection.new(response))
        when 200...400
          response
        when 400
          raise(BadRequest.new(response))
        when 401
          raise(UnauthorizedAccess.new(response))
        when 403
          raise(ForbiddenAccess.new(response))
        when 404
          raise(ResourceNotFound.new(response))
        when 405
          raise(MethodNotAllowed.new(response))
        when 406
          raise(NotAcceptable.new(response))
        when 409
          raise(ResourceConflict.new(response))
        when 422
          raise(ResourceInvalid.new(response))
        when 401...500
          raise(ClientError.new(response))
        when 500...600
          raise(ServerError.new(response))
        else
          raise(ConnectionError.new(response, "Unknown response code: #{response.code}"))
      end
    end
  end
end
