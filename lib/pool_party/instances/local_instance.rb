module PoolParty
  class LocalInstance
    include Monitors
    include Server
    include Scheduler
    
    attr_reader :cpu, :memory, :web
    
    def initialize
      super
    end
    
    def start!
      start_monitors!
      start_server!
    end
    
    def call(env)
      req = Rack::Request.new(env)
      resp = Rack::Response.new(env)
      if env["PATH_INFO"] == "/status"
        [200, {'Content-Type' => "text/html"}, status]
      else
        [404, {'Content-Type' => "text/html"}, "<h1>Not Found</h1>"]
      end
    end

    # Load the configuration parameters from the user-data when launched
    def config
      @config ||= YAML.load(URI.parse("http://169.254.169.254/latest/user-data"))
    end
    
    def start_monitors!
      run_thread_loop do
        add_task {update_monitors}
      end
    end
    
    def update_monitors
      @cpu = Cpu.monitor!
      @memory = Memory.monitor!
      @web = Web.monitor! port
    end
    
    def status
      { "cpu" => cpu, "memory" => memory, "web" => web }.to_yaml
    end
    
    def port
      config["port"]
    end
    
    def options
      OpenStruct.new(:logging => false)
    end
  end
end