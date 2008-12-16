require 'active_support'
require 'class_inheritable_attributes'
require 'ostruct'
require 'cgi'
require 'uri'
require 'net/https'
require 'web_service/core_ext'

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
