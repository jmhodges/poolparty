=begin rdoc
  CloudResourcer provides the cloud with convenience methods
  that you can call on your cloud. This is where the 
  
    instances 2..10
    
  method is stored, for instance. It's also where the key convenience methods are written
=end
require "ftools"

module PoolParty
  module CloudResourcer
    
    def plugin_directory(*args)
      args = [
        "#{::File.expand_path(Dir.pwd)}/plugins",
        "#{::File.expand_path(Base.poolparty_home_path)}/plugins"
      ] if args.empty?
      args.each {|arg| 
        return unless ::File.directory?(arg)
        Dir["#{arg}/*/*.rb"].each {|f| require f }
      }
    end
    
    # Store block
    def store_block(&block)
      @stored_block ||= block ? block : nil
    end
    
    def stored_block
      @stored_block
    end
    
    # This will run the blocks after they are stored if there is a block
    # associated
    def run_stored_block
      self.run_in_context @stored_block if @stored_block
    end
    
    # Set instances with a range or a number
    def instances(arg)      
      case arg
      when Range
        minimum_instances arg.first
        maximum_instances arg.last
      when Fixnum
        minimum_instances arg
        maximum_instances arg
      else
        raise SpecException.new("Don't know how to handle instances cloud input #{arg}")
      end
    end
    
    def setup_dev
      return true if ::File.exists?("#{remote_keypair_path}") || master.nil?
      # unless ::File.exists?("#{full_keypair_basename_path}.pub")
      #   cmd = "scp #{scp_array.join(" ")} #{Base.user}@#{master.ip}:.ssh/authorized_keys #{full_keypair_basename_path}.pub"
      #   vputs "Running #{cmd}"
      #   if %x[hostname].chomp == "master"
      #     Kernel.system("cat ~/.ssh/authorized_keys > #{full_keypair_basename_path}.pub")
      #   else
      #     Kernel.system(cmd)
      #   end
      # end
    end
    
    # Keypairs
    # Use the keypair path
    def keypair(*args)
      if args && !args.empty?
        args.each {|arg| (options[:keypairs] ||= [Key.new]).unshift Key.new(arg) }
      else
        options[:keypairs].select {|key| key.exists? }.first
      end
    end
    
    def full_keypair_path
      keypair.full_filepath
    end
                
    def number_of_resources
      arr = resources.map do |n, r|
        r.size
      end
      resources.map {|n,r| r.size}.inject(0){|sum,i| sum+=i}
    end
    
    def plugin_store
      @plugin_store ||= []
    end
    
    def realize_plugins!(force=false)
      plugin_store.each {|plugin| plugin.realize!(force) if plugin }
    end
    
    def plugin_store
      @plugins ||= []
    end
    
  end
end