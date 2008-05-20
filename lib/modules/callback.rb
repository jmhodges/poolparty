module PoolParty
  module Callbacks
    module ClassMethods
      def callback(type,m,e,*args, &block)
        case type
        when :before
          # orig_method = self.instance_method(m)          
          # process_method = instance_method(m)
          # first_method = instance_method(e)
          # 
          # define_method "orig_#{e}" do
          #   puts "in define_method"
          #   out = ""
          #   out << first_method.bind(self).call
          #   out << process_method.bind(self).call
          #   out
          # end
        end
      end
      def before(m,e,*args, &block)
        callback(:before, m,e,*args, &block)
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