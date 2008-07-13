module PoolParty
  class Tasks
    include Callbacks
    
    # Setup and define all the tasks
    def initialize
      yield self if block_given?
    end
    # Define the tasks in the rakefile
    # From the rakefile
    def define_tasks
      # Run the command on the local system
      def run(cmd)
        Kernel.system(cmd.runnable)
      end
      # Basic setup action
      def setup_application
        PoolParty.options(ARGV.dup)
      end
      
      # Require the poolparty specific tasks
      compiled_rakefile
      
      true
    end
    
    def compiled_rakefile
      return @compiled_rakefile if @compiled_rakefile
      
      rake_str = []
      
      Dir["#{File.expand_path(File.dirname(__FILE__))}/tasks/*.rake"].each { |t| rake_str << open(t).read }
      Dir["#{PoolParty.plugin_dir}/*/Rakefile"].each {|t| rake_str << open(t).read }
      
      @compiled_rakefile = eval(rake_str.join("\n")) # Not ideal
    end
  end
end