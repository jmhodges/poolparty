=begin rdoc
  Application
  This handles user interaction
=end
$:.unshift File.dirname(__FILE__)

module PoolParty  
  class Application
    class << self
      
      # The application options
      def options(opts={})
        @options ||= make_options(opts)
      end      
      # Make the options with the config_file overrides included
      # Default config file assumed to be at config/config.yml
      def make_options(opts={})
        load_options!(opts.delete(:optsparse) || {})
        default_options.merge!(opts)
        # If the config_file options are specified and not empty
        unless default_options[:config_file].nil? || default_options[:config_file].empty?
          require "yaml"
          # Try loading the file if it exists
          filedata = open(default_options[:config_file]).read if File.file?(default_options[:config_file])
          default_options.safe_merge!( YAML.load(filedata) ) if filedata # We want the command-line to overwrite the config file
        end

        OpenStruct.new(default_options)
      end

      # Load options via commandline
      def load_options!(opts={})
        require 'optparse'
        OptionParser.new do |op|
          op.banner = opts[:banner] if opts[:banner]
          op.on('-A key', '--access-key key', "Ec2 access key (ENV['ACCESS_KEY'])") { |key| default_options[:access_key] = key }
          op.on('-S key', '--secret-access-key key', "Ec2 secret access key (ENV['SECRET_ACCESS_KEY'])") { |key| default_options[:secret_access_key] = key }
          op.on('-I ami', '--image-id id', "AMI instance (default: 'ami-4a46a323')") {|id| default_options[:ami] = id }
          op.on('-k keypair', '--keypair name', "Keypair name (ENV['KEYPAIR_NAME'])") { |key| default_options[:keypair] = key }
          op.on('-b bucket', '--bucket bucket', "Application bucket") { |bucket| default_options[:shared_bucket] = bucket }          
          op.on('-D ec2 directory', '--ec2-dir dir', "Directory with ec2 data (default: '~/.ec2')") {|id| default_options[:ec2_dir] = id }
          op.on('-S services', '--services names', "Monitored services (default: '')") {|id| default_options[:services] = id }
          op.on('-c file', '--config-file file', "Config file (default: '')") {|file| default_options[:config_file] = file }
          op.on('-p port', '--host_port port', "Run on specific host_port (default: 7788)") { |host_port| default_options[:host_port] = host_port }
          op.on('-m monitors', '--monitors names', "Monitor instances using (default: 'web,memory,cpu')") {|s| default_options[:monitor_load_on] = s }          
          op.on('-o port', '--client_port port', "Run on specific client_port (default: 7788)") { |client_port| default_options[:client_port] = client_port }
          op.on('-O os', '--os os', "Configure for os (default: ubuntu)") { |os| default_options[:os] = os }          
          op.on('-e env', '--environment env', "Run on the specific environment (default: development)") { |env| default_options[:env] = env }
          op.on('-s size', '--size size', "Run specific sized instance") {|s| default_options[:size] = s}
          op.on('-u username', '--username name', "Login with the user (default: root)") {|s| default_options[:user] = s}
          op.on('-d user-data','--user-data data', "Extra data to send each of the instances (default: "")") { |data| default_options[:user_data] = data }
          op.on('-t seconds', '--polling-time', "Time between polling in seconds (default 50)") {|t| default_options[:polling_time] = t }
          op.on('-v', '--[no-]verbose', 'Run verbosely (default: false)') {|v| default_options[:verbose] = v}
          op.on('-i number', '--minimum-instances', "The minimum number of instances to run at all times (default 1)") {|i| default_options[:minimum_instances] = i}
          op.on('-x number', '--maximum-instances', "The maximum number of instances to run (default 3)") {|x| default_options[:maximum_instances] = x}
          
          op.on_tail("-V", "Show version") do
            puts Application.version
            exit
          end
          op.on_tail("-h", "-?", "Show this message") do
            puts op
            exit
          end
        end.parse!(ARGV.dup)
      end
      
      # Basic default options
      # All can be overridden by the command line
      # or in a config.yml file
      def default_options
        @default_options ||= {
          :host_port => 80,
          :client_port => 8001,
          :environment => 'development',
          :verbose => true,
          :logging => true,
          :size => "small",
          :polling_time => "30.seconds",
          :user_data => "",
          :heavy_load => 0.80,
          :light_load => 0.15,
          :minimum_instances => 1,
          :maximum_instances => 3,
          :access_key => ENV["ACCESS_KEY"],
          :secret_access_key => ENV["SECRET_ACCESS_KEY"],
          :config_file => ((ENV["CONFIG_FILE"] && ENV["CONFIG_FILE"].empty?) ? "config/config.yml" : ENV["CONFIG_FILE"]),
          :username => "root",
          :ec2_dir => ENV["EC2_HOME"],
          :keypair => ENV["KEYPAIR_NAME"],
          :ami => 'ami-4a46a323',
          :shared_bucket => "",
          :services => "nginx",
          :expand_when => "web_usage < 1.5\n memory_usage > 0.85",
          :contract_when => "cpu_usage < 0.20\n memory_usage < 0.10",
          :os => "ubuntu"
        }
      end
      # Services monitored by Heartbeat
      # Always at least monitors haproxy
      def managed_services
        "#{services}"
      end
      def master_managed_services
        "cloud_master_takeover #{services}"
      end
      def launching_user_data
        {:polling_time => polling_time}.to_yaml
      end
      # Keypair path
      # Idiom:
      #  /Users/username/.ec2/id_rsa-name
      def keypair_path
        "#{ec2_dir}/id_rsa#{keypair ? "-#{keypair}" : "" }"
      end
      # Are we in development or test mode
      def development?
        environment == 'development'
      end
      # Are we in production mode?
      def production?
        environment == "production"
      end
      # Are we in test mode
      def test?
        environment == "test"
      end
      def maintain_pid_path
        "/var/run/pool_maintain.pid"
      end
      # Standard configuration files
      %w(haproxy monit heartbeat heartbeat_authkeys).each do |file|
        define_method "#{file}_config_file" do
          File.join(File.dirname(__FILE__), "../..", "config", "#{file}.conf")
        end
      end
      def version
        "0.0.4"
      end
      
      # Call the options from the Application
      def method_missing(m,*args)
        options.methods.include?("#{m}") ? options.send(m,args) : super
      end
    end
        
  end
    
end