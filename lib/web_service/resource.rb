module WebService
  class Resource
    class_inheritable_attr_accessor :site, :credentials
    class_inheritable_attr_accessor :element_name, :singleton
    
    class << self
      include NamedRequestMethods
      include CRUDOperations
      
      def credentials
        super || site.credentials
      end
      
      def element_name
        super || self.element_name = begin
          klass = self
          while klass.name.to_s.empty?
            klass = klass.superclass
            raise NameError, "cannot determine element name from anonymous class" unless klass < Resource
          end
          klass.name.to_s.demodulize.underscore
        end
      end

      def belongs_to(*resource_names)
        (@belongs_to ||= []).concat(resource_names)
      end

      def has_many(*resource_names)
        resource_names.each do |res_name|
          class_eval %{
            def #{res_name}
              association_collection_from_name %(#{res_name})
            end
          }
        end
      end
      
    protected
    
      def remote_collection
        @remote_collection ||= RemoteCollection.new(self)
      end
    end

    include AttributeAccessors
    include NamedRequestMethods
    include CRUDOperations
    
    alias to_hash :attributes
    
    def ==(other)
      self.class === other && self.attributes == other.attributes
    end
    
    def save
      self.attributes = (saved? ? update((id unless self.class.singleton), attributes) : create(attributes)).attributes
      self
    end
    
    def saved?
      respond_to?(:id) && id
    end
    
    def destroy
      delete
      self
    end
    
  protected # for CRUDOperations
  
    def remote_collection
      @remote_collection ||= self.class.instance_eval { remote_collection }.with_nesting(nesting).extend(ImplicitId).set_related_resource(self)
    end
    
    def resource_class
      self.class
    end
    
  protected
    
    def association_collection_from_name(name)
      name.to_s.
        singularize.camelize.constantize.
        instance_eval { remote_collection }.with_nesting(nesting_up_to_self).
        extend CRUDOperations, NestingAsImplicitAttributes
    end
    
  private
  
    def nesting
      self.class.belongs_to.map { |res_name| [res_name, send("#{res_name}_id")] }
    end
    
    def nesting_up_to_self
      nesting + [[self.class.element_name, id]]
    end
    
    module NestingAsImplicitAttributes
      def implicit_attributes
        nesting.inject({}) { |attributes, (res_name, id)| attributes.update("#{res_name}_id" => id) }
      end
    end
    
    module ImplicitId
      def set_related_resource(resource)
        @related_resource = resource
        self
      end
      
      def implicit_id
        @related_resource.id if @related_resource.respond_to?(:id)
      end
    end
  end
end
