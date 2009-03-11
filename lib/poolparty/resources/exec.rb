module PoolParty    
  module Resources
    
    class Exec < Resource
      
      default_options({
        :path => "/usr/bin:/bin:/usr/local/bin:$PATH"
      })
      
      def present
        "running"
      end
      
      def key
        options[:name] || options[:command]
      end
                  
    end
    
  end
end