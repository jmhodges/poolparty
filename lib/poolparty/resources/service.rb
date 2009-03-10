module PoolParty    
  module Resources
        
    class Service < Resource
      
      default_options({
        :ensure => "running",
        :enable => true
      })
      
      def present
        "running"
      end
      def absent
        "stopping"
      end
    end
    
  end
end