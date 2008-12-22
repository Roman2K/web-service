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
          class_eval <<-RUBY
            def #{res_name}
              association_collection_from_name(#{res_name.to_sym.inspect})
            end
            def #{res_name}=(collection)
              #{res_name}.cache = collection
            end
          RUBY
        end
      end
      
      def has_one(*resource_names)
        resource_names.each do |res_name|
          class_eval <<-RUBY
            def #{res_name}
              association_collection_from_name(#{res_name.to_sym.inspect}).first
            end
          RUBY
        end
      end
      
    protected
    
      delegate :request, :to => :remote_collection
      
      def remote_collection
        @remote_collection ||= RemoteCollection.new(self)
      end
    end

    include AttributeAccessors
    include NamedRequestMethods
    include CRUDOperations
    
    alias to_hash :attributes
    
    def to_s
      [self.class, saved? ? "[#{id}]" : "(new)"].join
    end
    
    def inspect
      type_with_id = [self.class, saved? ? "[#{id}]" : "(new)"].join
      displayable_attributes_pairs =
        attributes.map { |name, value|
          value = value[0, 22] + '...' if String === value && value.length > 25
          "#{name}=#{value.inspect}" unless name == 'id'
        }.compact.sort
      "#<#{type_with_id}#{" " + displayable_attributes_pairs * " " if displayable_attributes_pairs.any?}>"
    end
    
    def ==(other)
      self.class === other && self.attributes == other.attributes
    end
    
    def save
      resource = if saved? then update((id unless self.class.singleton), attributes) else create(attributes) end
      self.attributes = resource.attributes if resource
      return self
    end
    
    def saved?
      respond_to?(:id) && id
    end
    
    def destroy
      delete
      return self
    end
    
  protected # for CRUDOperations
  
    delegate :request, :to => :remote_collection
    
    def remote_collection
      @remote_collection ||=
        self.class.instance_eval { remote_collection }.with_nesting(nesting).
        extend(ImplicitID).set_related_resource(self)
    end
    
    def resource_class
      self.class
    end
    
  protected
    
    def association_collection_from_name(name)
      @association_collections ||= {}
      @association_collections[name.to_s] ||= build_association_collection_from_name(name)
    end
    
  private
  
    def nesting
      self.class.belongs_to.map { |res_name| [res_name, send("#{res_name}_id")] }
    end
    
    def nesting_up_to_self
      nesting + [[self.class.element_name, id]]
    end
    
    def build_association_collection_from_name(name)
      name.to_s.
        singularize.camelize.constantize.
        instance_eval { remote_collection }.with_nesting(nesting_up_to_self).
        extend NamedRequestMethods, CRUDOperations, NestingAsImplicitAttributes
    end
    
    module NestingAsImplicitAttributes
      def implicit_attributes
        nesting.inject({}) { |attributes, (res_name, id)| attributes.update("#{res_name}_id" => id) }
      end
    end
    
    module ImplicitID
      def set_related_resource(resource)
        @related_resource = resource
        self
      end
      
      def implicit_id
        @related_resource.id if @related_resource.saved?
      end
    end
  end
end
