module PoolParty    
  module Resources
        
    class Symlink < Resource
            
      def source(i=nil)
        i ? options[:ensure] = i : options[:ensure]
      end
      
      def present
        options[:ensure]
      end
      
    end
    
  end
end