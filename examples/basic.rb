# Basic pool spec
# Shows global settings for the clouds

pool :application do
  
  instances 3..50
  keypair "auser"
  testing true
  
  cloud :app do    
    minimum_instances 1
    ami "ami-abc123"
    junk_yard_dogs "pains"
    
    cloud :inner do
      minimum_instances 14
    end
  end
  
  cloud :db do
    keypair "hotstuff_database"
    maximum_instances 20
    ami "ami-1234bc"
    junk_yard_dogs "are bad"
  end

end