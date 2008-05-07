module PoolParty
  extend self
  
  class ScheduleTasks
    attr_reader :tasks
    include ThreadSafeInstance
    
    def initialize
      @tasks = []
      run
    end 
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
    
    def <<(a)
      @tasks.push( Thread.new {Thread.stop;a.call} )
    end
    alias_method :push, :<<
        
    make_safe :<<
  end
  class Scheduler
    attr_reader :tasks
    
    def initialize
      @tasks = ScheduleTasks.new
    end
        
    def add_task(&blk)
      @tasks.push proc{blk.call}
    end
    
    def run_threads
      @tasks.run
    end
    def run_thread_loop
      Thread.start do
        loop do
          begin
            yield if block_given?
            run_threads
            sleep sleep_interval.seconds
          rescue Exception => e
            puts "There was an error in the run_thread_loop: #{e}"
          end
        end
      end
    end
        
  end
end
