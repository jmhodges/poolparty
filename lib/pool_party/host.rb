=begin rdoc
  Host
  This is the basis of the server for Pool Party
=end
module PoolParty
  extend self
  
  class Host < Remoting    
    attr_reader :bucket_instances
    
    def initialize
      super      
      start_monitor!
      start_proxy_server!      
    end
    # == PROXY
    # This is where Rack answers the request
    def call(env)      
      req = Rack::Request.new(env)
      inst = get_next_instance_for_proxy
      
      puts "using #{inst.ip} to call for #{req.path_info}"
      
      # Show a nice pretty error if we are development env
      if Application.development?
        inst.process(env, req)
      else
        begin
          inst.process(env, req)
        rescue Exception => e
          return_404(env, req, "error: #{e}")
        end        
      end
      
    end
    
    def build
      app = self
      # app = Rack::Session::Cookie.new(app, :key => rand_key(16)) if options.sessions == true
      app = Rack::CommonLogger.new(app) if options.logging == true
      app
    end
    
    def options
      Application.options
    end
    
    # Start the server to ping host the actual responses
    def start_proxy_server!
      puts "starting transparent monitoring on #{options.port}"
      require 'pp'
      begin
        server.run(build, :Port => options.port) do |server|
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
    
    def get_next_instance_for_proxy
      @running_instances.unshift @running_instances.pop      
    end   
    
    # == MONITORING
    # Monitor the health of the cloud
    # Start instances if there are below the minimum
    # Add instances when necessary (load or hits are too high to sustain)
    def start_monitor!
      run_thread_loop do
        add_task {launch_minimum_instances}
        add_task {update_instance_values}
        add_task {add_instance_if_load_is_high}
        add_task {terminate_instance_if_load_is_low}
      end
    end
    
    # Load and start the minimum number of instances
    def launch_minimum_instances
      request_launch_new_instances(minimum_instances - number_of_running_instances)
    end
    
    # update the instance values from ec2
    def update_instance_values
      @running_instances = get_instances_description.collect {|a| RemoteInstance.new(a) }.sort
    end
    
    def add_instance_if_load_is_high
    end
    def terminate_instance_if_load_is_low      
    end
    
    # Gives us the usage of method calling for the configuration
    def method_missing(m,*args)
      if config.include?("#{m}") 
        config["#{m}"]
      else
        super
      end
    end
    
    # Refactor this into something nice
    # Error message
    def return_404(env, req, mess=nil)
      resp = Rack::Response.new(env)
      body = "<h1>Error</h1><br />#{mess}"
      [404, {'Content-Type' => "text/html"}, body]
    end
    
  end
end