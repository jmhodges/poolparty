require File.join(File.dirname(__FILE__), "resource")

module PoolParty    
  module PluginModel
    
    def plugin(name=:plugin, cloud=nil, &block)
      plugins.has_key?(name) ? plugins[name] : (plugins[name] = PluginModel.new(name, &block))
    end
    alias_method :register_plugin, :plugin
    
    def plugins
      $plugins ||= {}
    end
    
    class PluginModel      
      attr_accessor :name, :klass
      
      def initialize(name,&block)
        symc = "#{name}".top_level_class.camelcase        
        klass = symc.class_constant(PoolParty::Plugin::Plugin, {:preserve => true}, &block)
        
        lowercase_class_name = symc.downcase
        # Store the name of the class for pretty printing later
        # klass.name = name
        # Add the plugin definition to the cloud as an instance method
        meth = <<-EOM
          def #{lowercase_class_name}(opts={}, &block)
            inst = PoolParty::#{lowercase_class_name.camelcase}Class.new(opts, &block)
            parent.plugin_store << inst if parent
            inst
          end
        EOM

        PoolParty::Cloud::Cloud.class_eval meth
      end
      
    end
    
  end
end