module PoolParty
  class Provider
    class << self
      attr_accessor :user_packages
    end
    
    def self.install_poolparty
      script=<<-EOS
#{load_packages.join("\n")}
#{ user_packages.map {|blk| blk.call if blk } }

policy :poolparty, :roles => :app do
  requires :git
  requires :ruby
  requires :failover
  requires :proxy
  requires :s3fs
  requires :rsync
  requires :required_gems
  #{user_install_packages.join("\n")}  
end

#{install_from_sprinkle_string}
      EOS
      
      PoolParty.message "Installing required poolparty paraphernalia"
      Sprinkle::Script.sprinkle script
    end
    
    def self.install_userpackages      
      script=<<-EOS
#{user_install_packages.join("\n")}

policy :userpackages, :roles => :app do
  #{ user_packages.map {|blk| blk.is_a?(String) ? blk : blk.bind(self).call } }
end        

#{install_from_sprinkle_string}
      EOS
      
      PoolParty.message "Installing user defined packages"
      Sprinkle::Script.sprinkle script# unless load_strings.empty?
    end
    
    def self.define_custom_package name=:userpackages, &block
      (user_install_packages << "requires :#{name}").uniq!
      user_packages << block
    end
    
    def self.define_user_package str="", &block
      user_packages << (block_given? ? block : str)
    end
    
    def self.define_user_install str="", &block
      user_install_packages << (block_given? ? block : str)
    end
    
    def self.reset!
      @@user_packages = @@load_strings == @user_package_names = nil
    end
    
    def self.user_packages
      @@user_packages ||= []
    end
    
    def self.user_install_packages
      @@load_strings ||= []
    end
    
    def self.user_install_package_names
      @@user_package_names ||= []
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
    set :user, "#{Application.username}"
    
    #{string_roles_from_ips}
  end
  
  source do
    prefix   '/usr/local'
    archives '/root/sources'
    builds   '/root/builds'
  end
    
end
      EOS
    end
        
    def self.string_roles_from_ips
      Master.cloud_ips.collect do |ip|
        "role :app, '#{Application.username}@#{ip}'"
      end.join("\n")
    end
    
  end
end