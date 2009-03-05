=begin rdoc
  DependencyResolver
  
  This acts as the interface between PoolParty's dependency tree
  and the dependency providers. To add a new DependencyResolver,
  overload this class with the appropriate calls
=end
module PoolParty
  class DependencyResolver
    
    attr_reader :properties_hash
    
    def initialize(hash)      
      raise DependencyResolverException.new('must pass a hash') if hash.nil? || !hash.instance_of?(Hash)
      @properties_hash = hash
    end
    
    # Compile the clouds properties_hash into the format required by the dependency resolver
    # This methods should be overwritten by the supclassed methods
    def compile()
      raise "Not Implemented"
    end
    
    def self.compile(hash)
      new(hash).compile
    end
    
  end
end