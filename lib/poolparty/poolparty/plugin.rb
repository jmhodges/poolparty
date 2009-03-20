require "#{::File.dirname(__FILE__)}/service.rb"

module PoolParty
  module Plugin
        
    class Plugin < PoolParty::Service
      include CloudResourcer
      include Resources
      include PoolParty::DependencyResolverCloudExtensions
            
      default_options({})
      
      def initialize(opts={}, parent=nil, &block)
        set_vars_from_options(opts) unless opts.empty?        
        block = Proc.new {enable} unless block
        super(&block)
        loaded(opts, &block)
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