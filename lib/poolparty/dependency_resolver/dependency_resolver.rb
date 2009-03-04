=begin rdoc
  DependencyResolver
  
  This acts as the interface between PoolParty's dependency tree
  and the dependency providers. To add a new DependencyResolver,
  overload this class with the appropriate calls
=end
module PoolParty
  class DependencyResolver
    
    attr_reader :tree_hash
    
    def initialize(hash={})
      @tree_hash = hash
    end
    
    def compile  
    end
    
    def self.compile(hash={})
      new(hash).compile
    end
    
  end
end