=begin rdoc
  Allow for plugins based in callbacks
  
  A plugin should be able to hook into any method and run their command
  either before or after the plugin.
=end
module PoolParty
  class Plugin
    
    # Create a class-level method for the name on the class
    # For instance:
    #   create_methods :install, RemoteInstance
    # will give the following methods to the class
    #   before_install and after_install on the RemoteInstance
    def self.create_methods(name, klass)
      str = ""
      %w(before after).each do |time|        
        str << <<-EOE
          def self.#{time}_#{name}(*meth)
            callee = self
            #{klass}.class_eval do
              meth.each {|m| #{time} :#{name}, {m.to_sym => callee.to_s}}
            end
          end
        EOE
      end
      eval str
    end
    
    %w(install configure associate_public_ip become_master).each do |method|
      create_methods method, RemoteInstance
    end    
    %w(start start_monitor scale_cloud reconfiguration add_instance terminate_instance check_stats).each do |method|
      create_methods method, Master
    end    
    %w(define_tasks).each do |method|
      create_methods method, Tasks
    end
    %w(run_tasks).each do |method|
      create_methods method, Scheduler
    end    
  end  
end