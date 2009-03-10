module PoolParty    
  module Resources
        
    class Package < Resource
      
      default_options({
        :ensure => "installed"
      })
      
    end
    
  end
end