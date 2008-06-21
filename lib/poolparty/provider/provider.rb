module PoolParty
  class Provider
    class << self
      attr_accessor :user_packages
    end
    
    def self.install_poolparty(ips)
      @ips = ips
      
      load_str = load_packages
            
      script=<<-EOS
        #{load_str.join("\n")}
        #{user_defined_packages.join("\n")}
        
        policy :poolparty, :roles => :app do
          requires :git
          requires :ruby
          requires :failover
          requires :proxy
          requires :monit
          requires :s3fs
          requires :rsync          
          requires :required_gems          
          
          #{user_packages.join("\n")}
        end        
        
        #{install_from_sprinkle_string}
      EOS
      
      PoolParty.message "Installing required poolparty paraphernalia"
      Sprinkle::Script.sprinkle script
    end
    
    def self.define_user_packages *strings
      strings.each do |str|
        user_packages << str
      end      
    end
    
    def self.user_defined_packages *strings
      strings.each do |str|
        load_strings << str
      end
      load_strings
    end
    
    def self.user_packages
      @user_packages ||= []
    end
    
    def self.load_strings
      @load_strings ||= []
    end
    
    def self.load_packages
      load_str = []
      returning load_str do
        Dir["#{File.expand_path(File.dirname(__FILE__))}/packages/*"].each {|f| load_str << open(f).read}
      end
    end
    
    def self.install_from_sprinkle_string
      <<-EOS
        deployment do
          delivery :vlad do 
            
            set :ssh_cmd, '#{RemoteInstance.ssh_string}'
            
            #{string_roles_from_ips(@ips || [])}            
          end
          
          source do
            prefix   '/usr/local'
            archives '/root/sources'
            builds   '/root/builds'
          end
            
        end
      EOS
    end
        
    def self.string_roles_from_ips(ips)
      ips.collect do |ip|
        "role :app, '#{ip}'"
      end.join("\n")
    end
    
  end
end