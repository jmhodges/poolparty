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
  module Scheduler
    attr_reader :tasks
        
    def tasks
      @tasks ||= ScheduleTasks.new
    end
        
    def add_task(&blk)
      tasks.push proc{blk.call}
    end
    def interval
      @interval ||= Application.polling_time
    end
    def run_threads
      tasks.run
    end
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
      
      if opts[:daemonize]
        daemonize(&block)
      else
        block.call
      end            
    end
    def reset!
      cached_variables.each {|cached| cached = nil }
    end
        
  end
end
