=begin rdoc
  Host
  This is the basis of the server for Pool Party
=end
module PoolParty
  extend self
  
  class Host < Remoting    
    include Server
    
    attr_reader :bucket_instances
    
    def initialize
      super      
    end
    
    def start!
      launch_minimum_instances
      
      start_monitor!
      start_server!
    end
    # == PROXY
    # This is where Rack answers the request
    def call(env)
      inst = get_next_instance_for_proxy
      return_error(503, env, "error") unless inst && inst.ip
      puts "== using #{inst.ip}"
      
      # Show a nice pretty error if we are development env
      if Application.development?
        inst.process(env)
      else
        begin
          inst.process(env)
        rescue Exception => e
          return_error(404, env, "error: #{e}")
        end        
      end
      
    end
    
    def options
      Application.options
    end
    
    def get_next_instance_for_proxy
      returning running_instances.shift do |inst|
        running_instances.push inst
      end
    end   
    
    # == MONITORING
    # Monitor the health of the cloud
    # Start instances if there are below the minimum
    # Add instances when necessary (load or hits are too high to sustain)
    def start_monitor!
      run_thread_loop do
        add_task {launch_minimum_instances} # If the base instances go down...
        add_task {update_instance_values} # Get the updated values
        add_task {add_instance_if_load_is_high}
        add_task {terminate_instance_if_load_is_low}
      end
    end
    
    # Load and start the minimum number of instances
    def launch_minimum_instances
      request_launch_new_instances(Application.minimum_instances - number_of_running_instances)
    end
    
    # update the instance values from ec2
    def running_instances
      @running_instances ||= update_instance_values
    end
    
    def update_instance_values
      @running_instances = list_of_running_instances.collect {|a| RemoteInstance.new(a) }.sort
    end
    
    def add_instance_if_load_is_high
    end
    def terminate_instance_if_load_is_low      
    end
        
    # Refactor this into something nice
    # Error message
    def return_error(num, env, mess=nil)
      resp = Rack::Response.new(env)
      body = "<h1>Error</h1><br />#{mess}"
      [num, {'Content-Type' => "text/html"}, body]
    end
    
    def on_server_exit
      request_termination_of_running_instances
    end
    
    def port
      Application.host_port
    end
  end
end