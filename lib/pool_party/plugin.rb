=begin rdoc
  Allow for plugins based in callbacks
  
  A plugin should be able to hook into any method and run their command
  either before or after the plugin.
=end
module PoolParty
  class Plugin
    
    def self.create_method(name, klass)
      %w(before after).each do |time|
        define_method ":#{time}_#{name}" do |meth|
          (klass.is_a?(String) ? eval(klass) : klass).class_eval "#{time}, :#{name}, :#{meth}, :class => '#{klass}'"
        end
      end
    end
    
    create_method :install, RemoteInstance
    create_method :configure, RemoteInstance
    
  end
end