=begin rdoc
  Host
  This is the basis of the server for Pool Party
=end
module PoolParty
  extend self
  
  class Host < Remoting
    attr_reader :bucket_instances
    
    # Monitor the health of the cloud
    # Start instances if there are below the minimum
    # Add instances when necessary (load or hits are too high to sustain)
    def start_monitor!
      run_thread_loop do
        add_thread {launch_minimum_instances}
      end
    end
    
    # This is where Rack answers the request
    def call(env)
      req = Rack::Request.new(env)
      
      # inst = (session(req)["instance"].is_responding? ? session(req)["instance"] : nil) if session?(req)
      inst ||= instance_with_lightest_load            
      
      puts "using #{inst.ip} to call for #{req.path_info}"
      
      # Show a nice pretty error if we are development env
      if Application.development?
        inst.process(env, req)
      else
        begin
          inst.process(env, req)
        rescue Exception => e
          Proxy.return_404(env, req, "error: #{e}")
        end        
      end
      
    end
    
    # Load and start the minimum number of instances
    def launch_minimum_instances
      server_pool_bucket_instances.size
    end
    
    def build
      app = self
      # app = Rack::Session::Cookie.new(app, :key => rand_key(16)) if options.sessions == true
      app = Rack::CommonLogger.new(app) if options.logging == true
      app
    end
    
    # Start the server to ping
    def start_monitoring_server!
      puts "starting transparent monitoring on #{options.port}"
      require 'pp'
      begin
        server.run(build, :Port => port) do |server|
          trap(:INT) do
            server.stop
          end
        end
      rescue Exception => e
        puts "There was an error: #{e}"
      end
    end
    
    # If we can, use Thin for the server, but if not, don't worry, we'll use mongrel
    def server
      @server ||= defined?(Rack::Handler::Thin) ? Rack::Handler::Thin : Rack::Handler::Mongrel
    end
    
    # The remote instance with the lightest load
    def instance_with_lightest_load
      registered_in_bucket.sort {|a,b| a.load <=> b.load }[0]
    end
    
    # A collection of RemoteInstances for every registered instance in the bucket
    def registered_in_bucket
      server_pool_bucket_instances.collect do |instance|
        instances << RemoteInstance.new(instance) unless instance.nil? && instance_ids.include?(instance.key)
      end
      instances
    end
    
    # :nodoc:
    def instance_ids
      instances.collect {|a| a }
    end
    # :nodoc:
    def instances
      @bucket_instances ||= []
    end
    
    # Resets this class's variables to reload
    def reset!
      @bucket_instances = nil
    end
    
    # Remove all the registered instances from the bucket
    def clear_bucket!
      server_pool_bucket.bucket_objects.each {|a| server_pool_bucket.delete_bucket_value a.key }
    end
    
    # Generate a random key for cookies
    def rand_key(size=8)
      Array.new(size) { rand(256) }.pack('C*').unpack('H*').first
    end
    
    def load_config!      
      @config ||= load_config_from_file!
    end
    
    # Gives us the usage of method calling for the configuration
    def method_missing(m,*args)
      if @config.include?("#{m}") 
        @config["#{m}"]
      else
        super
      end
    end
    
  end
end