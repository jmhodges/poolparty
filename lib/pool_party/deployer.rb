module PoolParty
  class Deployer        
    def self.install_on_roles(role=:app)
      script=<<-EOS
      require "deployment/pool_party"
      
      deployment do
        delivery :vlad do
          set :user, 'root'
          #{roles_for(role).join("\n")}
        end
      end
      EOS
      
      Sprinkle::Script.sprinkle script
    end
    
    def self.roles_for(role=:app)
      roles.select {|a| a =~ /role/}
    end
    
    def self.set_roles_for_instances_as(nodes, role=:app)
      nodes.each do |node|
        roles << "role :#{role}, '#{node.ip}'"
      end      
    end
    
    def self.roles
      @roles ||= []
    end
    
    def self.reset
      @roles = nil
    end
  end
end