require 'active_support'
require 'array_index_block_form'
require 'class_inheritable_attributes'
require 'ostruct'
require 'uri'
require 'net/https'

Object.class_eval do
  undef :id if method_defined?(:id)
end

def URI(object)
  URI === object ? object : URI.parse(object.to_s)
end

module WebService
  autoload :Site,                 'web_service/site'
  autoload :Resource,             'web_service/resource'
  autoload :AttributeAccessors,   'web_service/attribute_accessors'
  autoload :RemoteCollection,     'web_service/remote_collection'
  autoload :ResponseHandling,     'web_service/response_handling'
  autoload :NamedRequestMethods,  'web_service/named_request_methods'
  autoload :CRUDOperations,       'web_service/crud_operations'
  
  class Error < StandardError
  end
  class ResourceNotSaved < Error
  end
  class NotResourceClass < Error
  end
  
  class << self
    def logger
      @logger ||= begin
        require 'logger'
        Logger.new(STDOUT)
      end
    end
    attr_writer :logger
  end
  
  include ResponseHandling::Exceptions
end
