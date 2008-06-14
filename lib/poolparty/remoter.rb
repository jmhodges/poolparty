=begin rdoc
  Handle the remoting aspects of the remote_instances
  
  For now, default to using vlad
=end
require "vlad"

module PoolParty
  class Remoter
        
    # 
    # TODO: REPLACE THIS WITH Rake::RemoteTask
    # 
    
    # Scp src to dest on the instance
    def scp(src="", dest="", opts={})
      ssh("sudo mkdir -p #{opts[:dir]}") if opts[:dir]
      `scp #{opts[:switches]} -i #{Application.keypair_path} #{src} #{Application.username}@#{@ip}:#{dest}`
    end
    def scp_string(src,dest,opts={})
      str = ""
      str << "mkdir -p #{opts[:dir]}\n" if opts[:dir]
      str << "scp #{opts[:switches]} -i #{Application.keypair_path} #{src} #{Application.username}@#{@ip}:#{dest}"
      str.runnable
    end
    # Ssh into the instance or run a command, if the cmd is set
    def ssh(cmd="")
       ssh = "ssh -i #{Application.keypair_path} #{Application.username}@#{@ip}"
    
       cmd.empty? ? system("#{ssh}") : %x[#{ssh} '#{cmd.runnable}']
     end
    
  end
end