class WebServers
  plugin :apache do    
    attr_accessor :php
    
    def enable      
    end
    
    def enable_php
      @php = true
      php
    end
    
    def php
      @php
    end
    
    def site(name=:domain1, opts={})
      virtual_host name, opts
    end
    
    def virtual_host(name, opts={})
      opts = {
        :document_root => opts[:document_root] || "/www/#{name}/"
      }
    end        
  end
end
