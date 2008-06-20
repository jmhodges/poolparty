module PoolParty
  extend self
  # Schedule tasks container
  class ScheduleTasks
    include ThreadSafeInstance
    # Initialize tasks array and run
    def tasks
      @_tasks ||= []
    end
    # Synchronize the running threaded tasks
    def run
      unless tasks.empty?
        self.class.synchronize do
          tasks.reject!{|a|            
            begin
              a.run
              a.join
            rescue Exception => e    
              puts "There was an error in the task: #{e} #{e.backtrace.join("\n")}"
            end
            true
          }
        end
      end
    end
    # Add a task in a new thread
    def <<(a, *args)
      thread = Thread.new(a) do |task|
        Thread.stop
        Thread.current[:callee] = task
        a.call args
      end
      tasks << thread
    end
    alias_method :push, :<<
    # In the ThreadSafeInstance
    make_safe :<<
  end
  # Scheduler class
  module Scheduler
    attr_reader :tasker
    # Get the tasks or ScheduleTasks
    def _tasker
      @_tasker ||= ScheduleTasks.new
    end
    # Add a task to the new threaded block
    def add_task(&blk)
      _tasker.push proc{blk.call}
    end
    # Grab the polling_time
    def interval
      @interval ||= Application.polling_time
    end
    # Run the threads
    def run_threads
      _tasker.run
    end
    alias_method :run_tasks, :run_threads
    # Daemonize the process
    def daemonize
      PoolParty.message "Daemonizing..."
      
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
      pid
    end
    # Run the loop and wait the amount of time between running the tasks
    # You can send it daemonize => true and it will daemonize
    def run_thread_loop(opts={}, &block)
      block = lambda {        
        loop do
          begin
            run_thread_list(&block)
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
    
    def run_thread_list
      yield if block_given?
      run_threads
    end
    # Reset
    def reset!
      cached_variables.each {|cached| cached = nil }
    end
        
  end
end
