=begin rdoc
  Handle the remoting aspects of the remote_instances
  
  For now, default to using vlad
=end
module PoolParty
  module Remoter    
    require "vlad"
    include Callbacks
    # 
    # TODO: REPLACE THIS WITH Rake::RemoteTask
    # 
    before :scp, :set_hosts
    before :ssh, :set_hosts
    
    # Set the RemoteRake tasks
    def set_hosts
    end
    # Scp src to dest on the instance
    def scp(src="", dest="", opts={}, &block)
      unless block_given?        
        block = Proc.new {open(src).read}
      end
      sudo("mkdir -p #{opts[:dir]}") if opts[:dir]
      # `scp #{opts[:switches]} -i #{Application.keypair_path} #{src} #{Application.username}@#{@ip}:#{dest}`
      put dest, File.basename(src), &block
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
    
       cmd.empty? ? system("#{ssh}") : run(cmd.runnable)
     end
    
  end
end