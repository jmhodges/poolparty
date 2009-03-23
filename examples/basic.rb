# Basic pool spec
# Shows global settings for the clouds
pool :application do
  instances 3..50
  keypair "auser"
  testing true
  puts "parent in pool application: #{self.name}"
  
  cloud :app do
    puts "parent in cloud app: #{self.name}: #{parent.name}"
    minimum_instances 12
    ami "ami-abc123"
    junk_yard_dogs "pains"
    
    has_file :name => "/etc/init.d/motd", :content => "Welcome to your PoolParty instance"
  end
  
  cloud :db do
    puts "parent in cloud db: #{self.name}"
    minimum_instances 19
    keypair "hotstuff_database"
    maximum_instances 20
    ami "ami-1234bc"
    junk_yard_dogs "are bad"
  end

end