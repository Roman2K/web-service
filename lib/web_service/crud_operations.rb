module WebService
  module CRUDOperations
    include ResponseHandling::Exceptions
    include Enumerable
    
    delegate :each, :to => :all
    
    def all(*args)
      return @cache if @cache
      expect(request(:get, *args), Net::HTTPOK) do |data|
        instantiate_several_from_http_response_data(data)
      end
    end
    
    def cache=(collection)
      @cache = collection.map { |res| instantiate_resource(res) }
    end
    
    def flush_cache
      @cache = nil
      self
    end
    
    def first(*args)
      all(*args).first
    end
    
    def last(*args)
      all(*args).last
    end
    
    def find(id, *args)
      expect(request(:get, id, *args), Net::HTTPOK) do |data|
        instantiate_single_from_http_response_data(data)
      end
    end
    
    def [](id)
      find(id)
    rescue ResourceNotFound
      nil
    end
    
    def build(attributes={})
      default_attributes = respond_to?(:implicit_attributes) ? implicit_attributes : {}
      instantiate_resource(default_attributes.stringify_keys.merge(attributes.stringify_keys))
    end
    
    def create(attributes={})
      expect(request(:post, body_for_create_or_update(attributes)), Net::HTTPCreated, Net::HTTPAccepted) do |data|
        instantiate_single_from_http_response_data(data)
      end
    end
    
    def update(id, attributes={})
      expect(request(:put, id, body_for_create_or_update(attributes)), Net::HTTPOK, Net::HTTPAccepted) do |data|
        instantiate_single_from_http_response_data(data)
      end
    end
    
  private
  
    def element_name
      @element_name ||= respond_to?(:resource_class) ? resource_class.element_name : super
    end
    
    def expect(response, *types)
      case response
      when *types
        yield response.data
      else
        raise ConnectionError.new(response, "unexpected response")
      end
    end
    
    def body_for_create_or_update(attributes)
      {element_name => build(attributes).attributes}
    end
    
    def instantiate_single_from_http_response_data(data)
      return nil if data.to_s.blank?
      
      unless data.respond_to?(:key?) && data.respond_to?(:[])
        raise ArgumentError, "wrong data type for marshalled resource: #{data.class} (expected a Hash)"
      end
      unless data.key?(element_name)
        raise ArgumentError, "wrong format for marshalled resource: expected a Hash with #{element_name.inspect} as sole key"
      end
      instantiate_resource(data[element_name])
    end
    
    def instantiate_several_from_http_response_data(data)
      [data].flatten.map { |entry| instantiate_single_from_http_response_data(entry) }
    end
    
    def instantiate_resource(*args, &block)
      klass = respond_to?(:new) ? self : resource_class
      
      # TODO  Fix the need that hack:
      #
      #       It makes has_one saves work, as foo.bar builds a subclass of Bar
      #       with singleton=true so that the RemoteCollection of foo.bar will
      #       make POST requests to /foos/1/bar instead of /foos/1/bars.
      #
      #       See Resource#remote_collection
      #
      basic_collection = self if respond_to?(:resource_class) && resource_class.name.to_s.empty?
      
      resource = args.size == 1 && !block && klass === args.first ? args.first : klass.new(*args, &block)
      resource.instance_variable_set(:@basic_remote_collection, basic_collection)
      return resource
    end
  end
end
