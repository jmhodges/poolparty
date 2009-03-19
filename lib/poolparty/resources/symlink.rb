module PoolParty    
  module Resources
        
    class Symlink < Resource
            
      def source(i=nil)
        i ? options[:ensures] = i : options[:ensures]
      end
      
      def present
        options[:ensures]
      end
      
    end
    
  end
end