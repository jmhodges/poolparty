module PoolParty
  
  def context_stack
    $context_stack ||= []
  end
  
  class PoolPartyBaseClass
    include Configurable
    include CloudResourcer
    include PoolParty::DependencyResolverCloudExtensions
        
    def initialize(caller_parent, &block)
      set_parent_and_eval(&block)
    end
    
    def set_parent_and_eval(&block)
      @options = parent.options.merge(options) if parent && parent.is_a?(PoolParty::Pool::Pool)
      
      parent.add_service(self) if parent
      
      context_stack.push self
      instance_eval &block if block
      context_stack.pop
    end
    
    def parent
      context_stack.last
    end
    
    # Add to the services pool for the manifest listing
    def add_service(serv, extra_name="")
      subclass = "#{serv.class.to_s.top_level_class.underscore.downcase}#{extra_name}"
      lowercase_class_name = subclass.to_s.underscore.downcase || subclass.downcase
      
      services.merge!(lowercase_class_name.to_sym => serv)
    end
    # Container for the services
    def services
      @services ||= {}
    end
    
    def resources
      @resources ||= {}
    end
    
    def resource(type=:file)
      resources[type.to_sym] ||= []
    end
    
    
  end
end
