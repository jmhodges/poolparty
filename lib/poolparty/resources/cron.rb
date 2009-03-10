module PoolParty    
  module Resources
        
    class Cron < Resource
      
      # dsl_accessors [
      #   :hour, :minute, :month, :command, :user, :monthday, :weekday, 
      # ]
      
      default_options({
        :command => nil,
        :user => "root"
      })

    end
    
  end
end