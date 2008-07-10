=begin rdoc
  Handle the remoting aspects of the remote_instances
=end
require 'open4'
module PoolParty
  module Remoter        
    module ClassMethods
      def ssh_string
        (["ssh"] << ssh_array).join(" ")
      end
      def ssh_array
        ["-o StrictHostKeyChecking=no", "-l '#{Application.username}'", "-i '#{Application.keypair_path}'"]
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
          system("#{cmd} #{self.ip}") if self.class == RemoteInstance
        else
          target_hosts.each do |ip|
            arr << "#{cmd} #{ip} '#{command.runnable}'"
          end
        end
                
        run_array_of_tasks arr
      end
      
      def run_now command        
        run command unless command.empty?
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
      
      # Nearly Directly from vlad
      def run command, on=self
        cmd = [self.class.ssh_string, on.ip].compact
        result = []

        commander = cmd.join(" ") << " \"#{command.runnable}\""        
        
        pid, inn, out, err = Open4::popen4(commander)

        inn.sync   = true
        streams    = [out, err]
        out_stream = {
          out => $stdout,
          err => $stderr,
        }

        # Handle process termination ourselves
        status = nil
        Thread.start do
          status = Process.waitpid2(pid).last
        end

        until streams.empty? do
          # don't busy loop
          selected, = select streams, nil, nil, 0.1

          next if selected.nil? or selected.empty?

          selected.each do |stream|
            if stream.eof? then
              streams.delete stream if status # we've quit, so no more writing
              next
            end

            data = stream.readpartial(1024)
            out_stream[stream].write data

            if stream == err and data =~ /^Password:/ then
              inn.puts sudo_password
              data << "\n"
              $stderr.write "\n"
            end

            result << data
          end
        end

        PoolParty.message "execution failed with status #{status.exitstatus}: #{cmd.join ' '}" unless status.success?

        result.join
      end
      
    end
  
    def self.included(receiver)
      receiver.extend         ClassMethods
      receiver.send :include, InstanceMethods
    end
  end
end