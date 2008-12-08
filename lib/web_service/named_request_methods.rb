module WebService
  module NamedRequestMethods
    def post(*args, &block)
      request(:post, *args, &block).data
    end
    
    def get(*args, &block)
      request(:get, *args, &block).data
    end
    
    def put(*args, &block)
      request(:put, *args, &block).data
    end
    
    def delete(*args, &block)
      request(:delete, *args, &block).data
    end
  end
end
