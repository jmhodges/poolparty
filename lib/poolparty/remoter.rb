=begin rdoc
  Handle the remoting aspects of the remote_instances
  
  For now, default to using vlad
=end
require "rake_remote_task"
module PoolParty
  module Remoter        
    
    module ClassMethods      
    end
    
    module InstanceMethods
      include Callbacks
      
      def rt
        @rt ||= Rake::RemoteTask
      end
      
      def actions
        @actions ||= []
      end
      
      def scp local, remote, opts={}
        PoolParty.message "uploading #{File.basename(local)}"
        ssh("mkdir -p #{opts[:dir]}") if opts[:dir]

        data = open(local).read
        begin
          actions << rtask(:scp) do
            rsync local, remote
          end.execute
        rescue Exception => e        
        end      
      end

      def single_scp local, remote, opts={}
        scp local, remote, opts.merge({:single => self.ip})
      end

      def ssh command="", &block
        blk = Proc.new do
          run "\"#{command.runnable}\""
        end
        ssh = "ssh -i #{Application.keypair_path} #{Application.username}@#{@ip} "

        begin
          out = (command.empty? ? system("#{ssh}") : rtask(:ssh, &blk).execute )
        rescue Exception => e                            
        end
        out
      end

      def rtask(name, *args, &block)
        rt.enhance do
          remote_task(name.to_sym => args, &block)
        end
      end
      
      def execute_tasks(opts={}, &block)
        set_hosts(nil) unless opts[:dont_set_hosts]
        block.call
        actions.each {|a| puts "a: #{a}";a.execute }
      end
      def set_hosts(c=nil)
      end
      
    end
  
    def self.included(receiver)
      receiver.extend         ClassMethods
      receiver.send :include, InstanceMethods
    end
  end
end