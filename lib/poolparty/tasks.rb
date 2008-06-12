module PoolParty
  module TaskCommands
    # Run the command on the local system
    def run(cmd)
      system(cmd.runnable)
    end
    # Basic setup action
    def setup_application
      Application.options({:config_file => (ENV["CONFIG_FILE"] || ENV["config"]) })
    end
  end
  class Tasks
    include TaskCommands
    include Callbacks
    
    # Setup and define all the tasks
    def initialize
      yield self if block_given?
    end
    # Define the tasks in the rakefile
    # From the rakefile
    def define_tasks
      require "rake"
      # Require the poolparty specific tasks
      Dir["#{File.dirname(__FILE__)}/tasks/*.rake"].each { |t| load t }
      true
    end
    
    before :putsme, :congrats    
    def putsme
      puts "me!"
    end
    def congrats(h)
      puts "congrats"
    end
    
  end
end