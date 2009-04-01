require 'rubygems'
require 'net/ssh'

module PoolParty
  module Remote
    
    def target_host(dns_or_ip=nil)
      dns_or_ip ? @target_host=dns_or_ip : @target_host
    end
  
    # Simply shell out and call ssh, simple, reliable and fewest dependencies, but slow
    def simplest_run_remote(host=target_host, command=[], extra_ssh_ops={})
      command = command.compact.join(' && ') if command.is_a? Array
      cmd = "ssh #{host} #{ssh_options(extra_ssh_ops)} '#{command}'"
      puts "\n--------------------------------\nrunning_remote:\n #{cmd}\n"
      puts %x{#{cmd}}
    end
    
    def run_remote( hst, cmds )
      simplest_run_remote hst, cmds
    end
    
    def ssh_into(inst, extra_ssh_ops={} )
      ip =  inst.ip? ? inst.ip : inst
      Kernel.system("ssh #{ssh_options(extra_ssh_ops)} #{ip}")
    end
    
    def ssh_options(opts={})
      o = {"-i" => full_keypair_path,
           "-l" => user,
           "-o" =>"StrictHostKeyChecking=no"
           }.merge(opts)
      o.collect{ |k,v| "#{k} #{v}"}.join(' ')
    end
  
    def rsync( source_path, destination_path, rsync_opts=['-v -a'] )
      puts %x{ rsync -e 'ssh #{ssh_options}' #{rsync_opts.join(' ')} #{source_path}  root@#{target_host}:#{destination_path}}
    end
   
    def run_local(commands)
      commands.each do |cmd|
        puts `#{cmd}`
      end
    end

    def commands
      @commands ||= Array.new
    end

    # TODO: make extendable multithreaded version
    def execute!
      # netssh(target_host, commands)
      commands.each {|c| run_remote(target_host, c) }
    end
    
      def netssh(host, cmds, opts={})
        vputs "netssh is running commands on #{host} "
        vputs "commands = #{cmds.to_yaml}"
        ssh_options_hash = {:keys => [full_keypair_path],
                            :auth_methods => 'publickey',
                            :user     => 'root',
                            :paranoid => false,
                            :verbose => :debug
                           }.merge(opts)
        p ssh_options_hash                   
        Net::SSH.start(target_host, user, ssh_options_hash ) do |ssh|
          output = ssh.exec!("hostname# ")
          # open a new channel and configure a minimal set of callbacks, then run
          # the event loop until the channel finishes (closes)
          ssh.loop
          channel = ssh.open_channel do |ch|
            cmds.each do |command|
              ch.exec(command) do |ch, success|
                raise "could not execute command" unless success
                # "on_data" is called when the process writes something to stdout
                ch.on_data do |c, data|
                  $stdout.print data if data
                end
                # "on_extended_data" is called when the process writes something to stderr
                ch.on_extended_data do |c, type, data|
                  $stderr.print data
                end
                ch.on_close { vputs "\n- Done! -\n" }
              end
            end
          end
        end
      end   
    
    
##########################################################################################################   
# TODO: Delete deprecated commands below here
    
    def rsync_storage_files_to_command(remote_instance)
      #TODO: rsync_to_command("#{Default.storage_directory}/", Default.remote_storage_path, remote_storage_path) if remote_instance
      "#{rsync_command} #{Default.storage_directory}/ #{remote_instance.ip}:#{Default.remote_storage_path}" if remote_instance
    end
    # rsync a file to a node.  By default to the master node.
    def rsync_to_command(source, target=source, remote_instance=master)
      "#{rsync_command} #{source} #{remote_instance.ip}:#{target}"
    end
    def run_command_on_command(cmd="ls -l", remote_instance=nil)
      vputs "Running #{cmd} on #{remote_instance.name == %x[hostname].chomp ? "self (master)" : "#{remote_instance.name}"}"
      (remote_instance.nil? || remote_instance.name == %x[hostname].chomp) ? %x[#{cmd}] : "#{ssh_command(remote_instance)} '#{cmd}'"
    end
    def ssh_command(remote_instance)
      "#{ssh_string} #{remote_instance.ip}"
    end
    # Generic commandable strings
    def ssh_string
      (["ssh"] << ssh_array).join(" ")
    end
    # Array of ssh options
    # Includes StrictHostKeyChecking to no
    # Ssh with the user in Base
    # And including the keypair_path
    # "-l '#{Default.user}'", 
    def ssh_array
      ["-o StrictHostKeyChecking=no", "-l #{Default.user}", '-i "'+full_keypair_path+'"']
    end
    def scp_array
      ["-o StrictHostKeyChecking=no", '-i "'+full_keypair_path+'"']
    end
    def rsync_command
      "rsync -azP --exclude cache -e '#{ssh_string} -l #{Default.user}'"
    end
    def remote_ssh_array
      ["-o StrictHostKeyChecking=no", "-l '#{Default.user}'", '-i "'+remote_keypair_path+'"']
    end
    def remote_ssh_string
      (["ssh"] << remote_ssh_array).join(" ")
    end
    def remote_rsync_command
      "rsync -azP --exclude cache -e '#{remote_ssh_string}'"
    end
          
    def scp_to_command(source, dest=target, remote_instance=master)
      #TODO: check if source is Directory and add -r if it is
      "scp #{source} #{remote_instance.ip}:#{dest} #{scp_array.join(' ')}"
    end
    
    # Rsync a file or directory to a node.  Rsync to master by default
    def rsync_to(source, target=source, num=0)
      str = "#{rsync_to_command(source, target, get_instance_by_number( num ))}"
      dputs "Running: #{str}"
      verbose ?  Kernel.system(str) : hide_output {Kernel.system str}
    end
    
    # Rsync command to the instance
    def rsync_storage_files_to(instance=nil)
      hide_output {Kernel.system "#{rsync_storage_files_to_command(instance)}" if instance}
    end
    # Take the rsync command and execute it on the system
    # if there is an instance given
    def run_command_on(cmd, instance=nil)        
      Kernel.system "#{run_command_on_command(cmd, instance)}"
    end
    
    # Ssh into the instance given
    # def ssh_into(instance)
    #   cmd = "#{ssh_command(instance)}"
    #   vputs "Running #{cmd}"
    #   Kernel.system cmd if instance
    # end
    # Find the instance by the number given
    # and then ssh into the instance
    def ssh_into_instance_number(num=0)
      ssh_into( get_instance_by_number( num ) )
    end
    
    # Run command on the instance by the number
    def run_command_on_instance_number(cmd="ls -l", num=0)
      run_command_on(cmd, get_instance_by_number( num ) )
    end
    
  end
end