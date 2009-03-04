module PoolParty
  
  def context_stack
    $context_stack ||= []
  end
  
  class PoolPartyBaseClass
    include Configurable
    include CloudResourcer
        
    def initialize(parent, &block)      
      @parent = parent
      
      @options = parent.options.merge(options) if parent
      options.each {|k,v| instance_eval "def #{k};#{v};end" }
      
      context_stack.push self
      
      puts "parent: #{parent}"
      instance_eval &block if block
      context_stack.pop
    end
    
    def parent
      context_stack.last
    end
    
  end
end
