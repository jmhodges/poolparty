module PoolParty
  module Callbacks
    module ClassMethods
      def before_run(name, &block)
        
      end
    end
    
    module InstanceMethods
      
    end
    
    def self.included(receiver)
      receiver.extend         ClassMethods
      receiver.send :include, InstanceMethods
    end
  end
end