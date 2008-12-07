require 'test_helper'

class WebService::ResponseHandlingTest < Test::Unit::TestCase
  E = WebService::ResponseHandling::Exceptions::ConnectionError
  
  def test_connection_error_message
    # Can't use stub since stub(:method => :result) doesn't respond_to?(:method)
    response = Object.new
    def response.code; 400 end
    
    # Nil response / No custom message
    err = E.new(nil)
    assert_equal "Failed", err.to_s
    
    # Nil response + Custom message
    err = E.new(nil, "message")
    assert_equal "Failed: message", err.to_s
    
    # No response message / No custom message
    err = E.new(response)
    assert_equal "Failed with 400", err.to_s
    
    # Nil response message / No custom message
    def response.message; nil end
    err = E.new(response)
    assert_equal "Failed with 400", err.to_s
    
    # Blank response message / No custom message
    def response.message; "" end
    err = E.new(response)
    assert_equal "Failed with 400", err.to_s
    
    # Response message / No custom message
    def response.message; "Bad Request" end
    err = E.new(response)
    assert_equal "Failed with 400 (Bad Request)", err.to_s
    
    # Response message + Custom message
    err = E.new(response, "message")
    assert_equal "Failed with 400 (Bad Request): message", err.to_s
  end
end
