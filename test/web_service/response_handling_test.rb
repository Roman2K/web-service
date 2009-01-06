require 'test_helper'

class WebService::ResponseHandlingTest < Test::Unit::TestCase
  M = WebService::ResponseHandling
  
  def test_connection_error_message
    error_type = M::ConnectionError
    
    # Can't use stub since stub(:method => :result) doesn't respond_to?(:method)
    response = Object.new
    def response.code; 400 end
    
    # Nil response / No custom message
    err = error_type.new(nil)
    assert_equal "Failed", err.to_s
    
    # Nil response + Custom message
    err = error_type.new(nil, "message")
    assert_equal "Failed: message", err.to_s
    
    # No response message / No custom message
    err = error_type.new(response)
    assert_equal "Failed with 400", err.to_s
    
    # Nil response message / No custom message
    def response.message; nil end
    err = error_type.new(response)
    assert_equal "Failed with 400", err.to_s
    
    # Blank response message / No custom message
    def response.message; "" end
    err = error_type.new(response)
    assert_equal "Failed with 400", err.to_s
    
    # Response message / No custom message
    def response.message; "Bad Request" end
    err = error_type.new(response)
    assert_equal "Failed with 400 (Bad Request)", err.to_s
    
    # Response message + Custom message
    err = error_type.new(response, "message")
    assert_equal "Failed with 400 (Bad Request): message", err.to_s
  end
  
# protected

  def test_handle_response
    handler = Object.new.extend M
    
    assert_raise_with_code = lambda do |code, exc|
      response = stub(:code => code)
      assert_raise(exc) do
        handler.instance_eval { handle_response(response) }
      end
    end
    
    assert_raise_with_code[406, M::NotAcceptable]
    assert_raise_with_code[503, M::ServiceUnavailable]
    assert_raise_with_code[504, M::GatewayTimeout]
    
    response = stub(:code => 200)
    result = handler.instance_eval { handle_response(response) }
    assert_equal response, response
  end
end
