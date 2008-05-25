=begin rdoc
  Almost antiquated, used in the monitor
=end
module PoolParty
  module Server
    def build
      returning self do |app|
        Rack::CommonLogger.new(app) if options.logging == true
      end
    end
    
    # Start the server to ping host the actual responses
    def start_server!
      begin
        server.run(build, :Port => port) &server_loop
      rescue Exception => e
        puts "There was an error: #{e.nice_message}"
      end
    end
    
    def server_loop
      lambda {|server|
        trap("INT") do
          on_exit
          server.stop
        end
      }
    end
            
    # If we can, use Thin for the server, but if not, don't worry, we'll use mongrel
    def server
      @server ||= defined?(Rack::Handler::Thin) ? Rack::Handler::Thin : Rack::Handler::Mongrel
    end
    
    def port
      7788
    end
    
    def on_exit
    end
    alias_method :on_server_exit, :on_exit
  end
end