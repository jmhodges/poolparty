=begin rdoc
  Handle the remoting aspects of the remote_instances
=end
module PoolParty
  module Remoter        
    module ClassMethods
      def ssh_string
        "ssh -i #{Application.keypair_path} -o StrictHostKeyChecking=no -l #{Application.username}"
      end
      def rsync_string
        "rsync --delete -azP -e '#{ssh_string}' "
      end
    end
    
    module InstanceMethods      
      include Callbacks
      include Scheduler
      
      def rsync_tasks local, remote
        reset!
        returning scp_tasks do |tasks|
          target_hosts.each do |ip|
            tasks << "#{self.class.rsync_string} #{local} #{ip}:#{remote}"
          end
        end
      end
      
      def remote_command_tasks commands
        reset!
        commands = commands.join ' && ' if commands.is_a? Array
        
        returning ssh_tasks do |tasks|
          target_hosts.each do |ip|
            ssh_tasks << "#{self.class.ssh_string} #{ip} '#{commands}'"
          end
        end
      end
      
      def scp local, remote, opts={}          
        cmd = self.class.rsync_string
        arr = []
        
        target_hosts.each do |ip|
          arr << "#{cmd} #{local} #{ip}:#{remote}"
        end          
        
        run_array_of_tasks(arr)
      end

      def single_scp local, remote, opts={}
        scp local, remote, opts.merge({:single => self.ip})
      end

      def ssh command="", opts={}, &block
        cmd = self.class.ssh_string
        arr = []
        
        if command.empty?
          system("#{cmd} #{self.ip}")
        else
          target_hosts.each do |ip|
            arr << "#{cmd} #{ip} '#{command.runnable}'"
          end
        end
        
        run_array_of_tasks arr
      end
      
      def run_now command
        unless command.empty?
          Kernel.system "#{self.class.ssh_string} #{self.ip} #{command.runnable}"
        end
      end
            
      def ssh_tasks;@ssh_tasks ||= [];end
      def scp_tasks;@scp_tasks ||= [];end
            
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
      end
      
      def target_hosts
        @hosts ||= Master.collect_nodes {|a| a.ip }
      end
      
      def run_array_of_tasks(task_list)
        unless task_list.size == 0
          task_list.each do |task|
            add_task {Kernel.system("#{task}")}
          end          
          run_thread_list
        end
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