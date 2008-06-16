=begin rdoc
  Handle the remoting aspects of the remote_instances
  
  For now, default to using vlad
=end
require "rake_remote_task"
module PoolParty
  module Remoter        
    
    module ClassMethods      
    end
    
    module InstanceMethods
      def rt
        @rt ||= Rake::RemoteTask
      end

      def rtask(name, *args, &block)
        rt.remote_task(name.to_sym => args, &block)
      end
      
    end
  
    def self.included(receiver)
      receiver.extend         ClassMethods
      receiver.send :include, InstanceMethods
    end
  end
end