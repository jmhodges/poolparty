require "#{::File.dirname(__FILE__)}/service.rb"
require "#{::File.dirname(__FILE__)}/../provision/boot_strapper.rb"

module PoolParty
  module Plugin
        
    class Plugin < PoolParty::Service
      include CloudResourcer
      include PoolParty::DependencyResolverCloudExtensions
      include PoolParty::Callbacks
      
      def initialize(opts={}, prnt=nil, &block)
        setup_callbacks

        run_in_context do
          before_load(opts, &block)
        end
        
        block = Proc.new {enable} unless block
        
        @opts = (opts.is_a?(Hash) ? opts : {:name => opts})
        super(opts, &block)
        
        run_in_context do
          loaded @opts, &block
        end
                
        after_create
      end
      
      # Overwrite this method
      def before_load(o={}, &block)        
      end
      def loaded(o={}, &block)
      end
      # Callbacks available to plugins
      def after_create
      end
      
      def enable
      end
      def is_plugin?
        true
      end
      def cloud
        @parent
      end
      
      def bootstrap_gems *gems
        gems.each do |g|
          Provision::BootStrapper.gem_list << g unless Provision::BootStrapper.gem_list.include?(g)
        end
      end
      
      def bootstrap_commands cmds
        Provision::BootStrapper.class_commands << cmds
      end
      
      def configure_commands cmds
        Provision::DrConfigure.class_commands << cmds
      end
      
      def self.inherited(subclass)
        method_name = subclass.to_s.top_level_class.gsub(/pool_party_/, '').gsub(/_class/, '').downcase.to_sym
        add_has_and_does_not_have_methods_for(method_name)
      end
      
    end
    
  end
end