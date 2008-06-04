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
    #   before_install and after_install
    def self.create_methods(name, klass)
      %w(before after).each do |time|        
        str=<<-EOE
          def self.#{time}_#{name}(*meth)
            callee = self.name
            #{klass}.class_eval do
              meth.each do |m|
                #{time} self, :#{name}, {m => "#\{callee\}"}
              end
            end
          end
        EOE
        eval str
      end
    end
    
    # Quick hackz. Need to define this better
    create_methods :install, RemoteInstance
    create_methods :configure, RemoteInstance
    create_methods :associate_public_ip, RemoteInstance
    create_methods :become_master, RemoteInstance
    
    create_methods :start, Master
    create_methods :start_monitor, Master
    create_methods :scale_cloud, Master
    create_methods :reconfiguration, Master
    create_methods :add_instance, Master
    create_methods :terminate_instance, Master
    create_methods :check_stats, Master
    
    create_methods :run_tasks, Scheduler
  end
end