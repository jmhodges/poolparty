module PoolParty
  
  def context_stack
    $context_stack ||= []
  end
  
  class PoolPartyBaseClass
    include Configurable
    include CloudResourcer
        
    def initialize(caller_parent, &block)          
      set_parent_and_eval(&block)
    end
    
    def set_parent_and_eval(&block)
      @options = parent.options.merge(options) if parent
      
      parent.add_service(self) if parent
      
      context_stack.push self
      instance_eval &block if block
      context_stack.pop
    end
    
    def parent
      context_stack.last
    end
    
    # Add to the services pool for the manifest listing
    def add_service(serv)
      services.merge!(serv.class.downcase.to_sym => serv)
    end
    # Container for the services
    def services
      @services ||= []
    end
    
    def resources
      @resources ||= {}
    end
    
    def resource(type=:file)
      resources[type] ||= []
    end
    
    
  end
end
