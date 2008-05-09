module PoolParty
  module Server
    def build
      returning self do |app|
        Rack::CommonLogger.new(app) if options.logging == true
      end
    end
    
    # Start the server to ping host the actual responses
    def start_server!
      require 'pp'
      begin
        server.run(build, :Port => port) do |server|
          trap(:INT) do
            on_server_exit
            server.stop
          end
        end
      rescue Exception => e
        puts "There was an error: #{e.nice_message}"
      end
    end
            
    # If we can, use Thin for the server, but if not, don't worry, we'll use mongrel
    def server
      @server ||= defined?(Rack::Handler::Thin) ? Rack::Handler::Thin : Rack::Handler::Mongrel
    end
    
    def port
      7788
    end
    
    def on_server_exit
    end
  end
end