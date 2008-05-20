module PoolParty
  extend self
  class Tasks
    
    def initialize
      yield self if block_given?
      define_tasks!
    end
    
    def define_tasks!
      
      namespace(:ec2) do
        
        task :init do
          Application.options
        end

        desc "Shutdown all instances"
        task :shutdown_all => [:init, :clear] do
          begin
            PoolParty::Coordinator.shutdown_all!
            PoolParty::Coordinator.clear!
          rescue Exception => e
            puts "== there was an error: #{e}"
          end                    
        end
        
        desc "Clear server pool bucket"
        task :clear => [:init] do
          PoolParty::Coordinator.clear!
        end
        
        desc "List registered instances"
        task :list => [:init] do
          PoolParty::Coordinator.registered.each {|a| p a}
          puts `ec2-describe-instances | grep -v terminated | grep INSTANCE`
        end
        
        desc "Add and start an instance to the pool"
        task :start_new_instance => [:init] do
          PoolParty::Remoting.new.launch_new_instance!
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
      
      namespace(:bootstrap) do
        
        task :init do
          @cmd = []
        end
        
        task :go_working => [:init] do
          @cmd << "mkdir /usr/local/working"
          @cmd << "cd /usr/local/working"
        end
        
        desc "Executes the @cmd"
        task :exec_cmd do
          user = ENV["USER"] || "root"
          ip = ENV["ip"]
          raise Exception.new("You must include an ip (set with ip='127...')") unless ip
          cmd = "ssh -i #{Application.credentials} #{user}@#{ip} '#{@cmd}'"
          `#{cmd}`
        end
        
        Dir["#{File.dirname(__FILE__)}/#{File.basename(__FILE__, File.extname(__FILE__))}/**"].each {|a| require a }
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
    
  end
end