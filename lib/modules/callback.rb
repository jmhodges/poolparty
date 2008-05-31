module PoolParty
  module Callbacks
    module ClassMethods      
      attr_accessor :callbacks
      def define_callback_module(mod)
        (@callbacks ||= []) << mod
      end
      
      def callback(type,m,e,*args, &block)
        
        case type
        when :before          
          str=<<-EOD
            def #{m}              
              #{e}              
              yield if block_given?
              super
            end
          EOD
        when :after
          str=<<-EOD
            def #{m}
              super
              yield if block_given?
              #{e}
            end
          EOD
        end
                
        mMode = Module.new {eval str}
                
        define_callback_module(mMode)
      end
      def before(m,e,*args, &block)
        callback(:before,m,e,*args, &block)
      end
      def after(m,e,*args, &block)
        callback(:after,m,e,*args,&block)
      end
    end
    
    module InstanceMethods
      def initialize
        self.class.callbacks.each do |mod|
          self.extend(mod)
        end
      end
    end
    
    def self.included(receiver)
      receiver.extend         ClassMethods
      receiver.send :include, InstanceMethods
    end
  end
end