module WebService
  class Site
    def initialize(url)
      @url = URI(url)
    end
    
    # Returns a URI.
    def url(options={})
      @url
    end
    
    def credentials
      [url.user, url.password] if url.user
    end

    # Returns a String.
    def url_for(path, options={})
      url_to_path = url(options)
      url_to_path.path = path
      return url_to_path.to_s
    end
  
    def root
      url_for '/'
    end
    
    # This class is supposed to be used within a Rails app.
    class Switch < Site
      def initialize(public, local)
        @public, @local = URI.parse(public), URI.parse(local)
      end
      
      def url(options={})
        url = (Rails.env.production? || options[:public] ? @public : @local).dup
        url.port = @local.port if options[:public] && !Rails.env.production?
        return url
      end
    end
  end
end
