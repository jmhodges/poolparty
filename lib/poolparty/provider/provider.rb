require "sprinkle"

module PoolParty
  class Provider
    
    def self.install_poolparty(ips)
      @ips = ips
      
      load_str = []
      
      Dir["#{File.expand_path(File.dirname(__FILE__))}/packages/*"].each {|f| load_str << open(f).read}
            
      script=<<-EOS
        
        #{load_str.join("\n")}
        
        policy :poolparty, :roles => :app do
          requires :git
          requires :ruby
          requires :monit
          requires :s3fs
          requires :rsync
          requires :heartbeat
          requires :poolparty
        end        
        
        #{install_from_sprinkle_string(@ips)}
      EOS
            
      Sprinkle::Script.sprinkle script
    end
    
    def self.install_from_sprinkle_string
      <<-EOS
        deployment do 
          delivery :vlad do 
            
            set :ssh_cmd, '#{RemoteInstance.ssh_string}'
            
            #{string_roles_from_ips(@ips || [])}
            #{sprinkle_install}
          end
          
          source do
            prefix   '/usr/local'
            archives '/root/sources'
            builds   '/root/builds'
          end
            
        end
      EOS
    end
    
    # Serves as a placeholder for plugins
    def sprinkle_install
      PoolParty.message "Installing required poolparty paraphernalia"
    end
    
    def self.string_roles_from_ips(ips)
      ips.collect do |ip|
        "role :app, '#{ip}'"
      end.join("\n")
    end
    
  end
end