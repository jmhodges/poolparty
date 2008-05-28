module PoolParty
  module Callbacks
    module ClassMethods
      def callback(type,m,e,*args, &block)
        case type
        when :before          
          str=<<-EOD
            def old_#{m}
              #{e}
              super
            end
          EOD
        when :after
          str=<<-EOD
            def old_#{m}
              super
              #{e}
            end
          EOD
        end
        
        mMod = Module.new {eval str}
        
        module_eval %{
          alias_method :old_#{m}, :#{m}
        }
        
        self.send :define_method, "#{m}".to_sym, Proc.new {
          extend(mMod)
          method("old_#{m}".to_sym).call
        }
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