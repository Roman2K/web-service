module WebService
  module AttributeAccessors
    def initialize(attributes={})
      self.attributes = attributes
    end

    def attributes
      attribute_registry.dup
    end

    def attributes=(attributes)
      # Resolve single-key hash
      attributes = attributes[self.class.element_name] if attributes.size == 1 && attributes[self.class.element_name]
      
      # Clear previous attributes
      attribute_registry.clear
      
      # Assign the ID first, so that it can be used while assigning the rest of the attributes
      if id_key = [:id, "id"].find { |key| attributes.include? key }
        self.id = attributes.delete(id_key)
      end
      attributes.each { |name, value| send("#{name}=", value) }
    end

    # TODO handle the argument for whether to include singleton methods or not
    def methods
      super | attribute_accessor_methods.to_a
    end
    
    def respond_to?(method, include_private=false)
      super || attribute_accessor_methods.include?(TO_METHOD_NAME[method])
    end
    
    def read_attribute(attr_name)
      if (id = attribute_registry["#{attr_name}_id"])
        association_registry[attr_name.to_s] ||= resource_class_for(attr_name).find(id)
      else
        attribute_registry[attr_name.to_s] || association_registry[attr_name.to_s]
      end
    end
    
    def attribute_readable?(attr_name)
      attribute_registry.key?(attr_name) || association_registry.key?(attr_name) || attribute_registry.key?("#{attr_name}_id")
    end
    
    def write_attribute(attr_name, value)
      attr_name = attr_name.to_s
      resolve_record_descriptor = lambda { |descriptor|
        if Hash === descriptor && descriptor.size == 1
          if attributes = descriptor[attr_name]
            attributes
          elsif klass = resource_class_for?(descriptor.keys.first)
            klass.new(descriptor.values.first)
          end
        end
      }
      value = resolve_record_descriptor[value] || (value.kind_of?(Array) and value.map { |elt| resolve_record_descriptor[elt] || elt }) || value
      association_registry[$`] &&= nil if attr_name =~ /_id$/
      if value.nil?
        attribute_registry[attr_name] = nil
        attribute_registry["#{attr_name}_id"] &&= nil unless attr_name =~ /_id$/
        association_registry[attr_name] &&= nil
      elsif resource_class?(value.class)
        value.saved? or raise ResourceNotSaved, "resource must have an ID in order to be associated to another resource"
        attribute_registry["#{attr_name}_id"], association_registry[attr_name] = value.id, value
      elsif Hash === value and id = value["id"] and klass = resource_class_for?(attr_name)
        attribute_registry["#{attr_name}_id"], association_registry[attr_name] = id, klass.new(value)
      else
        attribute_registry[attr_name] = value
      end
    end
    
    def attribute_set?(attr_name)
      !attribute_registry[attr_name.to_s].blank? || !attribute_registry["#{attr_name}_id"].blank?
    end
    
  private
    
    TO_METHOD_NAME  = (Kernel.methods.first.kind_of?(String) ? :to_s : :to_sym).to_proc
    METHOD_SUFFIXES = ["", "=", "?"]
    
    def attribute_registry
      @attributes ||= {}
    end
    
    def association_registry
      @associations ||= {}
    end

    def method_missing(method_id, *args)
      method_name = method_id.to_s
      case
      when method_name =~ /=$/
        write_attribute($`, *args)
      when attribute_readable?(method_name)
        read_attribute(method_name, *args)
      when method_name =~ /\?$/
        super unless respond_to?($`)
        attribute_set?($`, *args)
      else
        super
      end
    end
    
    def attribute_accessor_methods
      METHOD_SUFFIXES.map do |suffix|
        (attribute_registry.keys + association_registry.keys).map do |attr_name|
          TO_METHOD_NAME["#{attr_name}#{suffix}"]
        end
      end.flatten
    end
    
    def resource_class_for(association_name)
      klass = association_name.to_s.camelize.constantize
      unless resource_class?(klass)
        raise NotResourceClass, "class #{klass} found for association `#{association_name}' is not a resource class"
      end
      klass
    end
    
    def resource_class_for?(association_name)
      resource_class_for(association_name)
    rescue NameError
      raise unless /uninitialized constant/ =~ $!
    rescue NotResourceClass
      raise unless /for association `#{association_name}'/ =~ $!
    end
    
    def resource_class?(klass)
      Class === klass && klass.respond_to?(:find) && klass.public_method_defined?(:saved?)
    end
  end
end
