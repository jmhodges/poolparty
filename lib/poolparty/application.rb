=begin rdoc
  Application
  This handles user interaction
=end
module PoolParty
  class Application
    class << self
      attr_accessor :verbose, :options
      
      # The application options
      def options(opts={})
        @options ||= make_options(opts)        
      end
      # Make the options with the config_file overrides included
      # Default config file assumed to be at config/config.yml
      def make_options(opts={})
        loading_options = opts.delete(:optsparse) || {}
        loading_options.merge!( opts.delete(:argv) || {} )
        
        config_file_location = (default_options[:config_file] || opts[:config_file])        
        # If the config_file options are specified and not empty
        unless config_file_location.nil? || config_file_location.empty?
          require "yaml"
          # Try loading the file if it exists
          filedata = File.open("#{config_file_location}").read if File.file?("#{config_file_location}")
          # We want the command-line to overwrite the config file
          default_options.merge!( YAML.load(filedata) ) if filedata
        end
        
        default_options.merge!(opts)
        load_options!(loading_options) # Load command-line options        
        default_options.merge!(local_user_data) unless local_user_data.nil?
        
        OpenStruct.new(default_options)
      end

      # Load options via commandline
      def load_options!(opts={})
        require 'optparse'
        OptionParser.new do |op|
          op.banner = opts[:banner] if opts[:banner]
          op.on('-A key', '--access-key key', "Ec2 access key (ENV['ACCESS_KEY'])") { |key| default_options[:access_key] = key }
          op.on('-S key', '--secret-access-key key', "Ec2 secret access key (ENV['SECRET_ACCESS_KEY'])") { |key| default_options[:secret_access_key] = key }
          op.on('-I ami', '--image-id id', "AMI instance (default: 'ami-40bc5829')") {|id| default_options[:ami] = id }
          op.on('-k keypair', '--keypair name', "Keypair name (ENV['KEYPAIR_NAME'])") { |key| default_options[:keypair] = key }
          op.on('-b bucket', '--bucket bucket', "Application bucket") { |bucket| default_options[:shared_bucket] = bucket }
          # //THIS IS WHERE YOU LEFT OFF
          op.on('-D working directory', '--dir dir', "Working directory") { |d| default_options[:working_directory] = d }
          
          op.on('--ec2-dir dir', "Directory with ec2 data (default: '~/.ec2')") {|id| default_options[:ec2_dir] = id }
          op.on('-r names', '--services names', "Monitored services (default: '')") {|id| default_options[:services] = id }
          op.on('-c file', '--config-file file', "Config file (default: '')") {|file| default_options[:config_file] = file }
          op.on('-l plugin_dir', '--plugin-dir dir', "Plugin directory (default: '')") {|file| default_options[:plugin_dir] = file }
          op.on('-p port', '--host_port port', "Run on specific host_port (default: 7788)") { |host_port| default_options[:host_port] = host_port }
          op.on('-m monitors', '--monitors names', "Monitor instances using (default: 'web,memory,cpu')") {|s| default_options[:monitor_load_on] = s }          
          op.on('-o port', '--client_port port', "Run on specific client_port (default: 7788)") { |client_port| default_options[:client_port] = client_port }
          op.on('-O os', '--os os', "Configure for os (default: ubuntu)") { |os| default_options[:os] = os }          
          op.on('-e env', '--environment env', "Run on the specific environment (default: development)") { |env| default_options[:environment] = env }
          op.on('-a address', '--public-ip address', "Associate this public address with the master node") {|s| default_options[:public_ip] = s}
          op.on('-s size', '--size size', "Run specific sized instance") {|s| default_options[:size] = s}
          op.on('-a name', '--name name', "Application name") {|n| default_options[:app_name] = n}
          op.on('-u username', '--username name', "Login with the user (default: root)") {|s| default_options[:user] = s}
          op.on('-d user-data','--user-data data', "Extra data to send each of the instances (default: "")") { |data| default_options[:user_data] = data }
          op.on('-i', '--install-on-boot', 'Install the PoolParty and custom software on boot (default: false)') {|b| default_options[:install_on_load] = true}
          op.on('-t seconds', '--polling-time', "Time between polling in seconds (default 50)") {|t| default_options[:polling_time] = t }
          op.on('-v', '--[no-]verbose', 'Run verbosely (default: false)') {|v| default_options[:verbose] = true}
          op.on('-n number', '--minimum-instances', "The minimum number of instances to run at all times (default 1)") {|i| default_options[:minimum_instances] = i.to_i}
          op.on('-x number', '--maximum-instances', "The maximum number of instances to run (default 3)") {|x| default_options[:maximum_instances] = x.to_i}
          
          op.on_tail("-V", "Show version") do
            puts Application.version
            exit
          end
          op.on_tail("-h", "-?", "Show this message") do
            puts op
            exit
          end
        end.parse!(opts[:argv] ? opts.delete(:argv) : ARGV.dup)
      end
      
      # Basic default options
      # All can be overridden by the command line
      # or in a config.yml file
      def default_options
        @default_options ||= {
          :app_name => "application_name",
          :host_port => 80,
          :client_port => 8001,
          :environment => 'development',
          :verbose => false,
          :logging => true,
          :size => "m1.small",
          :polling_time => "30.seconds",
          :user_data => "",
          :heavy_load => 0.80,
          :light_load => 0.15,
          :minimum_instances => 2,
          :maximum_instances => 4,
          :public_ip => "",
          :access_key => ENV["AWS_ACCESS_KEY_ID"],
          :secret_access_key => ENV["AWS_SECRET_ACCESS_ID"],
          :config_file => if ENV["CONFIG_FILE"] && !ENV["CONFIG_FILE"].empty?
            ENV["CONFIG_FILE"]
          elsif File.file?("config/config.yml")
            "config/config.yml"
          else
            nil
          end,
          :username => "root",
          :ec2_dir => ENV["EC2_HOME"],
          :keypair => ENV["KEYPAIR_NAME"],
          :ami => 'ami-44bd592d',
          :shared_bucket => "",
          :expand_when => "web < 1.5\n memory > 0.85",
          :contract_when => "cpu < 0.20\n memory < 0.10",
          :os => "ubuntu",
          :plugin_dir => "vendor",
          :install_on_load => false,
          :working_directory => Dir.pwd
        }
      end
      # Services monitored by Heartbeat
      def master_managed_services
        "cloud_master_takeover"
      end
      alias_method :managed_services, :master_managed_services
      def launching_user_data
        {:polling_time => polling_time, 
          :access_key => access_key, 
          :secret_access_key => secret_access_key,
          :user_data => user_data}.to_yaml
      end
      def local_user_data        
        begin
          @@timer.timeout(3.seconds) do
            @local_user_data ||=YAML.load(open("http://169.254.169.254/latest/user-data").read)
          end
        rescue Exception => e
          @local_user_data = {}
        end
      end
      # For testing purposes
      def reset!
        @local_user_data = nil
      end
      # Keypair path
      # Idiom:
      #  /Users/username/.ec2/id_rsa-name
      def keypair_path
        "#{ec2_dir}/id_rsa#{keypair ? "-#{keypair}" : "" }"
      end
      # Are we in development or test mode
      %w(development production test).each do |env|
        eval <<-EOE
          def #{env}?
            environment == '#{env}'
          end
        EOE
      end
      def environment=(env)
        environment = env
      end
      def maintain_pid_path
        "/var/run/pool_maintain.pid"
      end
      %w(scp_instances_script reconfigure_instances_script).each do |file|
        define_method "sh_#{file}" do
          File.join(File.dirname(__FILE__), "../..", "config", "#{file}.sh")
        end
      end
      # Standard configuration files
      %w(haproxy monit heartbeat heartbeat_authkeys).each do |file|
        define_method "#{file}_config_file" do
          File.join(File.dirname(__FILE__), "../..", "config", "#{file}.conf")
        end
      end
      def version
        PoolParty::Version.string
      end
      def install_on_load?(bool=false)
        options.install_on_load == true || bool
      end
      # Call the options from the Application
      def method_missing(m,*args)
        options.methods.include?("#{m}") ? options.send(m,args) : super
      end
    end
        
  end
    
end