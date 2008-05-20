require "tempfile"

module PoolParty
  class Ubuntu
    
    def exec_cmd(cmd="ls -l")
      system "rake instance:exec_remote ip='#{@ip}' cmd='#{cmd}'"
    end
    def exec_scp(src="", dest="")
      system "rake instance:scp ip='#{@ip}' src='#{src}' dest='#{dest}'"
    end
    
    def define_tasks!
      namespace(:ubuntu) do
        task :init do
          raise Exception.new("Please set the ip to do anything on an instance") unless ENV['ip']
          @ip = ENV['ip']
        end
        
        # This needs to be fixed
        desc "Install full stack"
        task :install => [:init] do
          cmd=<<-CMD
            rake os:ubuntu:monit:install
            rake os:ubuntu:monit:configure
            
            rake os:ubuntu:haproxy:install
            rake os:ubuntu:haproxy:configure
          CMD
          
          cmd.strip!
          cmd.gsub!(/\n/, " && ")
          system cmd
        end
        
        desc "Install full stack"
        task :reconfigure => [:init] do
          cmd=<<-CMD
            rake os:ubuntu:haproxy:configure
            rake os:ubuntu:monit:configure            
          CMD
          
          cmd.strip!
          cmd.gsub!(/\n/, " && ")
          system cmd
        end
        
        namespace(:monit) do
          desc "Install monit"
          task :install => [:init] do
            cmd=<<-EOC
              apt-get install monit &&
              mkdir /etc/monit
            EOC
            
            exec_cmd cmd
          end
          
          desc "Configure basic monit"
          task :configure => [:init] do
            # Scp the basic config file
            exec_scp(Application.monit_config_file, "/etc/monit/monitrc")
            # Scp all our custom monit scripts to the appropriate directory
            exec_cmd("mkdir /etc/monit.d")
            Dir["#{File.dirname(Application.monit_config_file)}/monit/*"].each do |f|
              exec_scp(f, "/etc/monit.d/#{File.basename(f)}")
            end
          end
        end

        namespace(:haproxy) do
          desc "Installs HAproxy"
          task :install => [:init] do
            @cmd=<<-EOC
              apt-get install haproxy
            EOC
            
            exec_cmd @cmd
          end
          task :configure => [:init] do
            master = Master.new
            nodes = master.nodes
            
            servers=<<-EOS
        listen web_proxy 127.0.0.1:#{Application.client_port}
          #{nodes.collect {|node| node.haproxy_entry}.join("\n")}
            EOS
                        
            # Fill in the gaps for the haproxy_config_file
            tempfile = Tempfile.new("rand#{rand(1000)}-#{rand(1000)}")
            tempfile.print(open(Application.haproxy_config_file).read.strip ^ {:servers => servers})
            tempfile.flush
            # Scp it up to the server
            exec_scp(tempfile.path, "/etc/haproxy.cfg")
          end
          
          task
        end

      end      
    end
  end
end


PoolParty::Ubuntu.new.define_tasks!