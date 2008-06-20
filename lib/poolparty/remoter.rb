=begin rdoc
  Handle the remoting aspects of the remote_instances
=end
module PoolParty
  module Remoter        
    module ClassMethods      
    end
    
    module InstanceMethods      
      include Callbacks
      include Scheduler
                  
      def scp local, remote, opts={}
        data = open(local).read
        begin
          
          cmd = "rsync --delete -azP -e '#{ssh_string} -l #{Application.username} -i #{Application.keypair_path}' "
          
          if opts[:dir]
            ssh("mkdir -p #{opts[:dir]}")
          end
          
          if opts[:single]
            scp_tasks << "#{cmd} #{local} #{Application.username}@#{opts[:single]}:#{remote}"
          else
            target_hosts.each do |ip|
              scp_tasks << "#{cmd} #{local} #{Application.username}@#{ip}:#{remote}"
            end
          end
          
        rescue Exception => e        
        end      
      end
      
      def ssh_string
        "ssh -i #{Application.keypair_path} -o StrictHostKeyChecking=no"
      end

      def single_scp local, remote, opts={}
        scp local, remote, opts.merge({:single => self.ip})
      end

      def ssh command="", opts={}, &block
        cmd = ssh_string
        if command.empty?
          system("#{cmd} #{Application.username}@#{self.ip}")
        else
          if opts[:single]
            ssh_tasks << "#{cmd} #{Application.username}@#{self.ip} '#{command.runnable}'"
          else
            target_hosts.each do |ip|
              ssh_tasks << "#{cmd} #{Application.username}@#{ip} '#{command.runnable}'"
            end
          end
        end
      end
      
      def install *names
        names.each {|name| install_tasks << name }
      end
      
      def ssh_tasks;@ssh_tasks ||= [];end
      def scp_tasks;@scp_tasks ||= [];end
      def install_tasks;@install_tasks ||= [];end
            
      def reset!
        @ssh_tasks = @scp_tasks = nil
        @hosts = nil
      end
      
      def execute_tasks(opts={})
        # reset!
        
        set_hosts(nil) unless opts[:dont_set_hosts]
        
        yield if block_given?
        
        run_array_of_tasks(scp_tasks)
        run_array_of_tasks(ssh_tasks)
        
        PoolParty.message "running #{ssh_tasks.size} tasks"
      end
      
      def target_hosts
        @hosts ||= Master.collect_nodes {|a| a.ip }
      end
      
      def run_array_of_tasks(task_list)
        add_task {`#{task_list.join(" && ")}`}
        run_thread_list
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