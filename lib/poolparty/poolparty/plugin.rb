module PoolParty
      
  module Plugin
        
    class Plugin < PoolPartyBaseClass
      include Configurable
      include CloudResourcer
      include Resources
      include PoolParty::DependencyResolverCloudExtensions
      
      class_inheritable_accessor :name
      
      default_options({})
      
      def initialize(opts={}, &block)
        store_block &block
        super(context_stack.last, &block)
      end
      
      # Overwrite this method
      def enable
      end
      
    end
    
  end
end