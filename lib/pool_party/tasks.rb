module PoolParty
  module TaskCommands
    # Run the command on the local system
    def run(cmd)
      system(cmd.runnable)
    end
    # Basic setup action
    def setup_application
      Application.options({:config_file => (ENV["CONFIG_FILE"] || ENV["config"]) })
    end
  end
  class Tasks
    include TaskCommands
    # Setup and define all the tasks
    def initialize
      yield self if block_given?
      define_tasks!
    end
    # Define the tasks in the rakefile
    def define_tasks!
      # Tasks dealing with only an instance
      namespace(:instance) do
        # Find the instance we want to deal with
        # interface can be: num=0, i=0, inst=0, 0
        # defaults to the master instance (0)
        task :init do
          num = (ENV['num'] || ENV["i"] || ENV["inst"] || ARGV.shift || 0).to_i          
          raise Exception.new("Please set the number of the instance (i.e. num=1, i=1, or as an argument)") unless num
          @node = PoolParty::Master.new.get_node(num)
        end
        # Ssh into the node
        desc "Remotely login to the remote instance"
        task :ssh => [:init] do
          @node.ssh
        end
        # Send a file to the remote instance
        # as designated by src='' and dest=''
        desc "Send a file to the remote instance"
        task :scp => [:init] do
          @node.scp ENV['src'], ENV['dest']
        end
        # Execute a command on the remote instance as designated
        # by cmd=''
        desc "Execute cmd on a remote instance"
        task :exec => [:init] do
          cmd = ENV['cmd'] || "ls -l"
          puts @node.ssh(cmd.runnable)
        end
        # Restart all the services monitored by monit
        desc "Restart all the services"
        task :reload => [:init] do
          @node.restart_with_monit
        end
        # Start all the services monitored by monit
        desc "Start all services"
        task :load => [:init] do
          @node.start_with_monit
        end
        # Stop the services monitored by monit
        desc "Stop all services"
        task :stop => [:init] do
          @node.stop_with_monit
        end
        # Install the required services on this node
        desc "Install stack on this node"
        task :install => :init do          
          @node.install_stack
          @node.configure
          @node.restart_with_monit
        end
        # Turnoff this instance
        desc "Teardown instance"
        task :shutdown => :init do
          `ec2-terminate-instances #{@node.instance_id}`
        end
        # Configure this node and start the services
        desc "Configure the stack on this node"
        task :configure => :init do
          @node.configure
          @node.restart_with_monit
        end
      end
      
      namespace(:dev) do
        task :init do
          setup_application
        end
        # Setup a basic development environment for the user 
        desc "Setup development environment specify the config_file"
        task :setup => :init do
          keyfilename = ".#{Application.keypair}_pool_keys"
          run <<-EOR
            echo 'export access_key=\"#{Application.access_key}\"' > $HOME/#{keyfilename}
            echo 'export SECRET_ACCESS_KEY=\"#{Application.secret_access_key}\"' >> $HOME/#{keyfilename}
            echo 'export EC2_HOME=\"#{Application.ec2_dir}\"' >> $HOME/#{keyfilename}
            echo 'export KEYPAIR_NAME=\"#{Application.keypair}\"' >> $HOME/#{keyfilename}
            echo 'export CONFIG_FILE=\"#{Application.config_file}\"' >> $HOME/#{keyfilename}
          EOR
        end
      end
      # Cloud tasks
      namespace(:cloud) do
        # Setup
        task :init do
          setup_application
          raise Exception.new("You must specify your access_key and secret_access_key") unless Application.access_key && Application.secret_access_key
        end
        # Install the stack on all of the nodes
        desc "Prepare all servers"
        task :prepare => :init do
          PoolParty::Master.new.nodes.each do |node|
            node.install_stack
          end
        end
        # Start the cloud
        desc "Start the cloud"
        task :start => :init do
          PoolParty::Master.new.start_cloud!
        end
        # Reload the cloud with the new updated data
        desc "Reload all instances with updated data"
        task :reload => :init do
          PoolParty::Master.new.nodes.each do |node|
            node.configure
            node.restart_with_monit
          end
        end
        # List the cloud
        desc "List cloud"
        task :list => :init do
          master = PoolParty::Master.new
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
        # Shutdown the cloud
        desc "Shutdown the entire cloud"
        task :shutdown => :init do
          PoolParty::Master.new.request_termination_of_all_instances
        end
        # Maintain the cloud in a background process
        desc "Maintain the cloud (run on the master)"
        task :maintain => :init do
          begin
            PoolParty::Master.new.start_monitor!
          rescue Exception => e
            puts "There was an error starting the monitor: #{e}"
          end
        end
        # Deploy task. 
        # TODO: Find a beautiful way of updating the user-defined configuration
        # data
        desc "Deploy web application from production git repos specified in config file"
        task :deploy => :init do
          puts "Deploying web app on nginx"
        end
      end
      
      # Nearly antiquated tasks
      namespace(:ec2) do        
        task :init do
          Application.options
        end
        # Start a new instance in the cloud
        desc "Add and start an instance to the pool"
        task :start_new_instance => [:init] do
          puts PoolParty::Remoting.new.launch_new_instance!
        end
        # Stop all the instances via command-line
        desc "Stop all running instances"
        task :stop_running_instances => [:init] do
          Thread.new {`ec2-describe-instances | grep INSTANCE | grep running | awk '{print $2}' | xargs ec2-terminate-instances`}
        end
        # Reboot the instances via commandline
        desc "Restart all running instances"
        task :restart_running_instances => [:init] do
          Thread.new {`ec2-describe-instances | grep INSTANCE | grep running | awk '{print $2}' | xargs ec2-reboot-instances`}
        end
      end
      # Tasks to be run on the server
      namespace(:server) do                
        task :init  do
          PoolParty::Coordinator.init(false)
        end
        # bundle, upload and register your bundle on the server
        desc "Bundle, upload and register your ami"
        task :all => [:bundle, :upload, :register] do
          puts "== your ami is ready"
        end
        # Cleanup the /mnt directory
        desc "Clean the /mnt directory"
        task :clean_mnt do
          `rm -rf /mnt/image* img*`
        end
        # Before we can bundle, we have to make sure we have the cert and pk files
        desc "Ensure the required bundle files are present in /mnt"
        task :check_bundle_files do
          raise Exception.new("You must have a private key in your /mnt directory") unless File.exists?("/mnt/pk-*.pem")
          raise Exception.new("You must have your access key in your /mnt directory") unless File.exists?("/mnt/cert-*.pem")          
        end
        # Bundle the image
        desc "Bundle this image into the /mnt directory"
        task :bundle => [:clean_mnt, :check_bundle_files] do
          puts `ec2-bundle-vol -k /mnt/pk-*.pem -u '#{Planner.user_id}' -d /mnt -c /mnt/cert-*.pem -r i386`
        end
        # Upload the bundle into the app_name bucket
        desc "Upload the bundle to your bucket with a unique name: deletes old ami"
        task :upload => [:init, :delete_bucket] do
          puts `ec2-upload-bundle -b #{Planner.app_name} -m /mnt/image.manifest.xml -a #{Planner.access_key} -s #{Planner.secret_access_key}`
        end
        # Register the bucket with amazon and get back an ami
        desc "Register the bundle with amazon"
        task :register do
          puts `ec2-register -K /mnt/pk-*.pem -C /mnt/cert-*.pem #{Planner.app_name}/image.manifest.xml`
        end
        # Delete the bucket
        desc "Delete the bucket with the bundle under tha app name"
        task :delete_bucket do
          Planner.app_name.delete_bucket 
        end
      end      
    end    
    
  end
end