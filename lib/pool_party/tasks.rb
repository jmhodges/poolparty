module PoolParty
  module TaskCommands
    def exec_cmd(cmd="ls -l")
      system "rake instance:exec_remote ip='#{@ip}' cmd='#{cmd}' 2>/dev/null"
    end
    def exec_scp(src="", dest="")
      system "rake instance:scp ip='#{@ip}' src='#{src}' dest='#{dest}'"
    end
    def run(cmd)
      system cmd.strip.gsub(/\n/, " && ")
    end
    def setup_application
      Application.options({:config_file => (ENV["CONFIG_FILE"] || ENV["config"]) })
    end
  end
  class Tasks
    include TaskCommands
    def initialize
      yield self if block_given?
      define_tasks!
    end
    
    def define_tasks!
      
      namespace(:instance) do
        task :init do
          @num = (ENV['num'] || ENV["i"] || ARGV[1]).to_i
          raise Exception.new("Please set the number of the instance (i.e. num=1, i=1, or as an argument)") unless @num
        end
        desc "Remotely login to the remote instance"
        task :ssh => [:init] do
          PoolParty::Master.new.get_node(@num).ssh
        end
        desc "Send a file to the remote instance"
        task :scp => [:init] do
          PoolParty::Master.new.get_node(@num).scp ENV['src'], ENV['dest']
        end
        desc "Execute cmd on a remote instance"
        task :exec_remote => [:init] do
          cmd = ENV['cmd'] || "ls -l"
          PoolParty::Master.new.get_node(@num).ssh cmd
        end
        desc "Restart all the services"
        task :reload => [:init] do
          PoolParty::Master.new.get_node(@num).restart_with_monit
        end
        desc "Start all services"
        task :load => [:init] do
          PoolParty::Master.new.get_node(@num).start_with_monit
        end
        desc "Stop all services"
        task :stop => [:init] do
          PoolParty::Master.new.get_node(@num).stop_with_monit
        end
        desc "Install stack on this node"
        task :install => :init do
          node = PoolParty::Master.new.get_node(@num)
          node.install_stack
          node.configure
          node.restart_with_monit
        end
        desc "Configure the stack on this node"
        task :configure => :init do
          node = PoolParty::Master.new.get_node(@num)
          node.configure
          node.restart_with_monit
        end
        namespace(:monit) do
          desc "Configure basic monit"
          task :configure => [:init] do
            PoolParty::Master.new.get_node(@num).configure_monit
          end
        end
      end
      
      namespace(:dev) do
        task :init do
          # COME BACK TO THIS
          setup_application
        end
        desc "Setup development environment specify the config_file"
        task :setup => :init do
          keyfilename = ".#{Application.keypair}_amazon_keys"
          run <<-EOR
            echo 'export ACCESS_KEY_ID=\"#{Application.access_key_id}\"' > $HOME/#{keyfilename}
            echo 'export SECRET_ACCESS_KEY=\"#{Application.secret_access_key}\"' >> $HOME/#{keyfilename}
            echo 'export EC2_HOME=\"#{Application.ec2_dir}\"' >> $HOME/#{keyfilename}
            echo 'export KEYPAIR_NAME=\"#{Application.keypair}\"' >> $HOME/#{keyfilename}
            echo 'export CONFIG_FILE=\"#{Application.config_file}\"' >> $HOME/#{keyfilename}
          EOR
        end
      end
      namespace(:cloud) do
        task :init do
          setup_application
          raise Exception.new("You must specify your access_key_id and secret_access_key") unless Application.access_key_id && Application.secret_access_key
        end
        desc "Prepare all servers"
        task :prepare => :init do
          PoolParty::Master.new.nodes.each do |node|
            node.install_stack
          end
        end
        desc "Start the cloud"
        task :start => :init do
          PoolParty::Master.new.start_cloud!
        end
        desc "Reload all instances with updated data"
        task :reload => :init do
          PoolParty::Master.new.nodes.each do |node|
            system "rake instance:reconfigure_and_reload ip='#{node.ip}'"
          end
        end
        desc "List cloud"
        task :list => :init do
          master = PoolParty::Master.new
          master.reset!
          num = master.number_of_pending_and_running_instances
          if num > 0
            puts "-- CLOUD (#{num})--"
            master.nodes.each do |node|
              puts node.description
            end
          else
            puts "Cloud is not running"
          end
        end
        desc "Teardown the entire cloud"
        task :teardown => :init do
          PoolParty::Master.new.request_termination_of_all_instances
        end
        desc "Maintain the cloud (run in a cron-job)"
        task :maintain => :init do
          begin
            PoolParty::Master.new.start_monitor!
          rescue Exception => e
            puts "There was an error starting the monitor: #{e}"
          end
        end
      end
      
      namespace(:ec2) do
        
        task :init do
          Application.options
        end
        
        desc "Add and start an instance to the pool"
        task :start_new_instance => [:init] do
          puts PoolParty::Remoting.new.launch_new_instance!
        end
        
        desc "Stop all running instances"
        task :stop_running_instances => [:init] do
          Thread.new {`ec2-describe-instances | grep INSTANCE | grep running | awk '{print $2}' | xargs ec2-terminate-instances`}
        end
        
        desc "Restart all running instances"
        task :restart_running_instances => [:init] do
          Thread.new {`ec2-describe-instances | grep INSTANCE | grep running | awk '{print $2}' | xargs ec2-reboot-instances`}
        end
        
        desc "Stop a random instance"
        task :stop_random_instance => [:init] do
          PoolParty::Coordinator.get_random_instance.stop!
        end
        
        desc "Log on to instance"        
        task :login => [:init] do
          `ssh root@#{PoolParty::Coordinator.get_random_instance.external_ip}`
        end
        
        desc "Clean up cookie bucket"
        task :cleanup_cookies => [:init] do
          Rack::Session::Cookie.cleanup_sessions
        end
      end
            
      namespace(:server) do                
        task :init  do
          PoolParty::Coordinator.init(false)
        end
        desc "Bundle, upload and register your ami"
        task :all => [:bundle, :upload, :register] do
          puts "== your ami is ready"
        end
        desc "Clean the /mnt directory"
        task :clean_mnt do
          `rm -rf /mnt/image* img*`
        end
        desc "Ensure the required bundle files are present in /mnt"
        task :check_bundle_files do
          raise Exception.new("You must have a private key in your /mnt directory") unless File.exists?("/mnt/pk-*.pem")
          raise Exception.new("You must have your access key in your /mnt directory") unless File.exists?("/mnt/cert-*.pem")          
        end
        desc "Bundle this image into the /mnt directory"
        task :bundle => [:clean_mnt] do
          puts `ec2-bundle-vol -k /mnt/pk-*.pem -u '#{Planner.user_id}' -d /mnt -c /mnt/cert-*.pem -r i386`
        end        
        desc "Upload the bundle to your bucket with a unique name: deletes old ami"
        task :upload => [:init, :delete_bucket] do
          puts `ec2-upload-bundle -b #{Planner.app_name} -m /mnt/image.manifest.xml -a #{Planner.access_key_id} -s #{Planner.secret_access_key}`
        end
        desc "Register the bundle with amazon"
        task :register do
          puts `ec2-register -K /mnt/pk-*.pem -C /mnt/cert-*.pem #{Planner.app_name}/image.manifest.xml`
        end
        desc "Delete the bucket with the bundle under tha app name"
        task :delete_bucket do
          Planner.app_name.delete_bucket 
        end
      end
      
    end
    
    def method_missing(m, *args)
      begin
        Application.send m, args
      rescue Exception => e
        super
      end            
    end
    
  end
end