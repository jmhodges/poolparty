=begin rdoc
  Application
  This handles user interaction
=end
module PoolParty
  extend self
  
  class Application        
    class << self
            
      def options(opts={})
        @options ||= make_options(opts)
      end
      
      def make_options(opts={})
        load_options!
        default_options.merge!(opts)
        
        unless default_options[:config_file].empty?
          require "yaml"
          filedata = open(default_options[:config_file]).read
          default_options.merge!( YAML.load(filedata) ) if filedata
        end
        
        OpenStruct.new(default_options)
      end

      # Load options 
      def load_options!
        require 'optparse'
        OptionParser.new do |op|
          op.on('-A key', '--access-key key', "Ec2 access key (ENV['ACCESS_KEY'])") { |key| default_options[:access_key_id] = key }
          op.on('-S key', '--secret-access-key key', "Ec2 secret access key (ENV['SECRET_ACCESS_KEY'])") { |key| default_options[:secret_access_key] = key }
          op.on('-I ami', '--image-id id', "AMI instance (default: 'ami-4a46a323')") {|id| default_options[:ami] = id }
          op.on('-k keypair', '--keypair name', "Keypair name (ENV['KEYPAIR_NAME'])") { |key| default_options[:keypair] = key }
          op.on('-D ec2 directory', '--ec2-dir dir', "Directory with ec2 data (default: '~/.ec2')") {|id| default_options[:ec2_dir] = id }
          op.on('-c file', '--config-file file', "Config file (default: '')") {|file| default_options[:config_file] = file }
          op.on('-p port', '--host_port port', "Run on specific host_port (default: 7788)") { |host_port| default_options[:host_port] = host_port }
          op.on('-o port', '--client_port port', "Run on specific client_port (default: 7788)") { |client_port| default_options[:client_port] = client_port }
          op.on('-e env', '--environment env', "Run on the specific environment (default: development)") { |env| default_options[:env] = env }
          op.on('-s size', '--size size', "Run specific sized instance") {|s| default_options[:size] = s}
          op.on('-u username', '--username name', "Login with the user (default: root)") {|s| default_options[:user] = s}
          op.on('-d user-data','--user-data data', "Extra data to send each of the instances (default: "")") { |data| default_options[:user_data] = data }
          op.on('-t seconds', '--polling-time', "Time between polling in seconds (default 50)") {|t| default_options[:polling_time] = t }
          op.on('-v', '--[no-]verbose', 'Run verbosely (default: false)') {|v| default_options[:verbose] = v}
          op.on('-i number', '--minimum-instances', "The minimum number of instances to run at all times (default 1)") {|i| default_options[:minimum_instances] = i}
          op.on('-x number', '--maximum-instances', "The maximum number of instances to run (default 3)") {|x| default_options[:maximum_instances] = x}
          op.on('-w seconds', '--interval-wait-time', "The number of seconds to wait between shutdown or startup of an instance (default 5.minutes)") {|w| default_options[:interval_wait_time] = w}          

          op.on_tail("-h", "--help", "Show this message") do |o|
            puts "op: #{o}"
            exit
          end          
        end.parse!(ARGV.dup)
      end

      def default_options
        @default_options ||= {
          :run => true,
          :host_port => 80,
          :client_port => 8001,
          :environment => 'development',
          :verbose => false,
          :logging => true,
          :size => "small",
          :polling_time => "50",
          :interval_wait_time => "300",
          :user_data => "",
          :heavy_load => 0.80,
          :light_load => 0.15,
          :minimum_instances => 1,
          :maximum_instances => 3,
          :access_key_id => ENV["ACCESS_KEY"],
          :secret_access_key => ENV["SECRET_ACCESS_KEY"],
          :config_file => "",
          :username => "root",
          :ec2_dir => "~/.ec2",
          :keypair => ENV["KEYPAIR_NAME"],
          :ami => 'ami-4a46a323'
        }
      end
      
      def keypair_path
        "#{ec2_dir}/id_rsa-#{keypair}"
      end
      def development?
        environment == 'development'
      end
      
      def launching_user_data
        {:polling_time => polling_time}.to_yaml
      end      
      def root_dir
        File.join File.dirname(__FILE__), %w(..)
      end
      
      def haproxy_config_file
        File.join(root_dir, "..", "config", "haproxy.conf")
      end      
      def monit_config_file
        File.join(root_dir, "..", "config", "monit.conf")
      end
          
      def method_missing(m,*args)
        options.methods.include?("#{m}") ? options.send(m,args) : super
      end
             
    end
  end
    
end