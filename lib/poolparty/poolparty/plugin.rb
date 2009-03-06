require "#{::File.dirname(__FILE__)}/service.rb"

module PoolParty
  module Plugin
        
    class Plugin < PoolParty::Service
      include Configurable
      include CloudResourcer
      include Resources
      include PoolParty::DependencyResolverCloudExtensions
            
      default_options({})
      
      def initialize(opts={}, &block)
        # store_block &block
        super(parent, &block)
      end
      
      def realize!(force=false)
        force ? force_realize! : (@realized ? nil : force_realize!)
      end
      
      def force_realize!
        # run_setup(parent, false, &stored_block)
        enable unless stored_block
      end
      
      # Overwrite this method
      def enable
      end
      
      
      
    end
    
  end
end