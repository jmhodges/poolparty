require "#{::File.dirname(__FILE__)}/service.rb"

module PoolParty
  module Plugin
        
    class Plugin < PoolParty::Service
      include CloudResourcer
      include PoolParty::DependencyResolverCloudExtensions
            
      default_options({})
      
      def initialize(opts={}, prnt=nil, &block)
        block = Proc.new {enable} unless block

        @opts = opts
        
        proc = Proc.new {
          block.call if block
          loaded(@opts, &block)
        }        
        
        super(opts, &proc)
        
        @opts = nil
      end
      
      # Overwrite this method
      def loaded(o={}, &block)
      end
      def enable
      end
      
      def self.inherited(subclass)
        method_name = subclass.to_s.top_level_class.gsub(/pool_party_/, '').gsub(/_class/, '').downcase.to_sym        
        add_has_and_does_not_have_methods_for(method_name)
      end
      
    end
    
  end
end