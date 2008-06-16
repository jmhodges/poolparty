=begin rdoc
  Handle the remoting aspects of the remote_instances
  
  For now, default to using vlad
=end
require "rake_remote_task"
module PoolParty
  module Remoter        
    
    module ClassMethods      
      include Callbacks
      before :scp, :set_hosts
      before :ssh, :set_hosts
    end
    
    module InstanceMethods
      include Callbacks
      # 
      # Using Vlad, for the time being
      #       
      # Scp src to dest on the instance
      # def scp(src="", dest="", opts={}, &block)
      #   unless block_given?        
      #     block = Proc.new {open(src).read}
      #   end
      #   sudo("mkdir -p #{opts[:dir]}") if opts[:dir]
      #   # `scp #{opts[:switches]} -i #{Application.keypair_path} #{src} #{Application.username}@#{@ip}:#{dest}`
      #   put dest, File.basename(src), &block
      # end
      def scp_string(src,dest,opts={})
        str = ""
        str << "mkdir -p #{opts[:dir]}\n" if opts[:dir]
        str << "scp #{opts[:switches]} -i #{Application.keypair_path} #{src} #{Application.username}@#{@ip}:#{dest}"
        str.runnable
      end
      
      after :initialize, :set_hosts
      def rt
        @rt ||= Rake::RemoteTask
      end

      def rtask(name, *args, &block)
        rt.remote_task(name.to_sym => args, &block)
      end
      
    end
  
    def self.included(receiver)            
      receiver.extend         Callbacks
      receiver.extend         ClassMethods
      receiver.send :include, InstanceMethods
    end
  end
end