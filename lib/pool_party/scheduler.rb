module PoolParty
  extend self
  # Schedule tasks container
  class ScheduleTasks
    attr_reader :tasks
    include ThreadSafeInstance
    # Initialize tasks array and run
    def initialize
      @tasks = []
      run
    end
    # Synchronize the running threaded tasks
    def run
      unless @tasks.empty?
        self.class.synchronize do
          @tasks.reject!{|a| 
            begin
              a.run;a.join
            rescue Exception => e    
              puts "There was an error in the task: #{e} #{e.backtrace.join("\n")}"
            end
            true
          }
        end
      end
    end
    # Add a task in a new thread
    def <<(a)
      @tasks.push( Thread.new {Thread.stop;a.call} )
    end
    alias_method :push, :<<
    # In the ThreadSafeInstance
    make_safe :<<
  end
  # Scheduler class
  module Scheduler
    attr_reader :tasks
    # Get the tasks or ScheduleTasks
    def tasks
      @tasks ||= ScheduleTasks.new
    end
    # Add a task to the new threaded block
    def add_task(&blk)
      tasks.push proc{blk.call}
    end
    # Grab the polling_time
    def interval
      @interval ||= Application.polling_time
    end
    # Run the threads
    def run_threads
      tasks.run
    end
    # Daemonize the process
    def daemonize
      puts "Daemonizing..."
      
      pid = fork do
        Signal.trap('HUP', 'IGNORE') # Don't die upon logout
        File.open("/dev/null", "r+") do |devnull|
          $stdout.reopen(devnull)
          $stderr.reopen(devnull)
          $stdin.reopen(devnull) unless @use_stdin
        end
        yield if block_given?
      end
      Process.detach(pid)      
    end
    # Run the loop and wait the amount of time between running the tasks
    # You can send it daemonize => true and it will daemonize
    def run_thread_loop(opts={})
      block = lambda {        
        loop do
          begin
            yield if block_given?
            run_threads
            wait interval
            reset!
          rescue Exception => e
            puts "There was an error in the run_thread_loop: #{e}"
          end
        end
      }
      # Run the tasks
      opts[:daemonize] ? daemonize(&block) : block.call   
    end
    # Reset
    def reset!
      cached_variables.each {|cached| cached = nil }
    end
        
  end
end
