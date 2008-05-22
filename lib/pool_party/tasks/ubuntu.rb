require "tempfile"

module PoolParty
  class Ubuntu
    include TaskCommands
    
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
            rake instance:ubuntu:monit:install            
            rake instance:ubuntu:haproxy:install
          CMD
          
          run cmd
        end
        
        desc "Restart all the services using monit"
        task :reload => [:init] do
          run "rake instance:reload"
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
        end
        
        namespace(:nginx) do
          desc "Installs nginx"
          task :install => [:init] do
            exec_cmd "apt-get install nginx"
          end
        end

        namespace(:haproxy) do
          desc "Installs HAproxy"
          task :install => [:init] do
            @cmd=<<-EOC
              apt-get install haproxy && rm /etc/haproxy.cfg
            EOC
            
            exec_cmd @cmd
          end
        end

      end      
    end
  end
end


PoolParty::Ubuntu.new.define_tasks!