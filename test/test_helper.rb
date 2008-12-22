require 'test/unit'
require 'mocha'
require 'test_unit_ext'

require 'net/http'
Net::HTTP.class_eval do
  undef :start
end

require 'web_service'
WebService::Resource.site = WebService::Site.new("http://example.com")
WebService.logger = Logger.new(STDERR)
WebService.logger.level = Logger::ERROR

class Foo < WebService::Resource
  has_many :bars
  has_one  :bar
end
class Bar < WebService::Resource
  belongs_to :foo
end

Test::Unit::TestCase.class_eval do
  def expect_request(resource_or_collection, method, path, details)
    connection  = stub
    response    = Net::HTTPResponse::CODE_TO_OBJ[details[:return][:status].to_s].new(*[stub_everything] * 3)
    body        = nil
    
    collection =
      case resource_or_collection
      when WebService::RemoteCollection
        resource_or_collection
      else
        resource_or_collection.ieval { remote_collection }
      end
    
    collection.
      stubs(:open_http_connection_to).
      yields(connection).
      returns(response)
    
    connection.expects(:request).with { |req, body|
      assert_equal(method.to_s.upcase, req.method)
      assert_equal(path, req.path)
      assert_equal(details[:body], ActiveSupport::JSON.decode(body || "null"))
      true
    }.returns(response)
    
    response.metaclass.instance_eval do
      define_method(:code) { details[:return][:status].to_s }
      define_method(:data) { details[:return][:body] }
    end
  end
end
