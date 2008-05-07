module PoolParty
  extend self
    
  class Schedule
    # Create a new scheduler
    def scheduler(create_new=false)
      @scheduler = nil if create_new
      @scheduler ||= Scheduler.new
    end
    # Add a threaded task to the scheduler
    def add_thread(opts={}, &blk)
      scheduler.add_task &blk
    end
    # Join and run all the threads
    def run_threads(&block)
      scheduler.run_threads &block
    end
    # Run the threaded loop on the threads (scheduler)
    def run_thread_loop(&block)
      scheduler.run_thread_loop &block
    end
  end  
  
end