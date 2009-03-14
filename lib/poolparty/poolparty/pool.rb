module PoolParty
  module Pool
    
    def pool(name=:app, &block)
      pools[name] ||= Pool.new(name, &block)
    end
    
    def pools
      $pools ||= {}
    end
    
    def with_pool(pl, opts={}, &block)
      raise CloudNotFoundException.new("Pool not found") unless pl
      pl.options.merge!(opts) if pl.options
      pl.run_in_context &block if block
    end
    
    def set_pool_specfile(filename)
      $pool_specfile = filename unless $pool_specfile
    end
        
    def reset!
      $pools = $clouds = $plugins = @describe_instances = nil
    end

    class Pool < PoolParty::PoolPartyBaseClass
      include PrettyPrinter
      include CloudResourcer
      include Remote
      
      @defaults = {
        :access_key => Base.access_key,
        :secret_access_key => Base.secret_access_key,
        :minimum_instances => 1,
        :maximum_instances => 4
      }
      define_defaults(@defaults)
      
      def initialize(name,&block)
        @pool_name = name
        @pool_name.freeze
        
        ::PoolParty.context_stack.clear
        
        set_pool_specfile get_latest_caller
        setup_defaults
        # run_in_context &block if block
        # run_setup(self, &block)
        super(&block)
      end
      def load_from_file(filename=nil)
        module_eval open(file).read, filename if filename
      end
      def pool_name
        @pool_name
      end
      alias :name :pool_name
      def parent;nil;end
      
      def setup_defaults
        plugin_directory "#{pool_specfile ? ::File.dirname(pool_specfile) : Dir.pwd}/plugins"
        PoolParty::Extra::Deployments.include_deployments "#{Dir.pwd}/deployments"
      end
      
      def pool_clouds
        returning Array.new do |arr|
          clouds.each do |name, cl|
            arr << cl if cl.parent.name == self.name
          end
        end
      end
      
    end
    
    # Helpers
    def remove_pool(name)
      pools.delete(name) if pools.has_key?(name)
    end
  end
end