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
end
class Bar < WebService::Resource
  belongs_to :foo
end

Test::Unit::TestCase.class_eval do
  def expect_request(resource, method, path, details)
    connection  = stub
    response    = Net::HTTPResponse::CODE_TO_OBJ[details[:return][:status].to_s].new(*[stub_everything] * 3)
    body        = nil
    
    patch_collection = lambda do |collection|
      collection.
        stubs(:open_http_connection_to).
        yields(connection).
        returns(response)
    end
    
    collection = resource.ieval { remote_collection }
    if details[:once_nested]
      collection.metaclass.class_eval do
        old_with_nesting = instance_method(:with_nesting)
        define_method(:with_nesting) do |*args|
          returning(old_with_nesting.bind(self).call(*args)) do |nested_collection|
            patch_collection.call(nested_collection)
          end
        end
      end
    else
      patch_collection.call(collection)
    end

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
