module PoolParty
  module Callbacks
    module CallbackMethods      
    end
    module ClassMethods
      def callback(type,m,e,*args, &block)
        case type
        when :before
        end
      end
      def before(m,e,*args, &block)
        callback(:before,m,e,*args, &block)
      end
      def after(m,e,*args, &block)
        callback(:after,m,e,*args,&block)
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