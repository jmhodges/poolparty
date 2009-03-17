module PoolParty    
  module Resources
        
    class Package < Resource
      
      default_options({
        :ensures => "installed"
      })
      
    end
    
  end
end