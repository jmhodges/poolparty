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
        pool = ThreadPool.new(10)
        tasks.each do |task|
          puts "Running #{task}"
          pool.process {task.call}
        end
        pool.join()
      end
    end
    # Add a task in a new thread
    def <<(a, *args)
      tasks << a
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
      _tasker.push blk
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
    def run_thread_loop(opts={}, &blk)
      block = lambda {        
        loop do
          begin
            yield if block_given?
            add_task { Signal.trap("INT") { exit } }            
            run_thread_list
            PoolParty.message "Waiting: #{interval}"
            wait interval
          rescue Exception => e
            Process.kill("INT", Process.pid)
          end
        end
      }
      # Run the tasks
      opts[:daemonize] ? daemonize(&block) : block.call   
    end
    
    def run_thread_list      
      run_threads
    end
        
  end
end
