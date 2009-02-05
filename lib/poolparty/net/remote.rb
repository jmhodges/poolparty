require File.dirname(__FILE__) + "/remoter"

class Object
  def remote_bases
    $remote_bases ||= []
  end
  # Register the remoter base in the remote_bases global store
  def register_remote_base(*args)
    args.each do |arg|
      base_name = "#{arg}".downcase.to_sym
      (remote_bases << base_name) unless remote_bases.include?(base_name)
    end
  end
  alias :available_bases :remote_bases
end

module PoolParty
  module Remote
    module ClassMethods
    end
    
    module InstanceMethods
      def using(t)
        @cloud = self
        if t && self.class.available_bases.include?(t.to_sym)
          unless using_remoter?
            self.class.send :attr_reader, :remote_base
            self.class.send :attr_reader, :parent_cloud

            klass = "#{t}".classify.constantize
            @remote_base = klass.send :new
            @parent_cloud = @cloud
          end
        else
          puts "Unknown remote base" 
        end
      end
      
      def using_remoter?
        @remote_base
      end
      
      def method_missing_with_remoter(m, *args, &block) #:nodoc:
        if @remote_base && @remote_base.respond_to?(m)
          @remote_base.send m, *args, &block
        else
          method_missing_without_remoter(m, *args, &block)
        end
      end
      
    end
    
    def self.included(receiver)
      receiver.extend         ClassMethods
      receiver.send :include, InstanceMethods
      
      receiver.send :alias_method, :method_missing_without_remoter, :method_missing
      receiver.send :alias_method, :method_missing, :method_missing_with_remoter
    end

    class Remote
      include PoolParty::Remote::Remoter
    end
  end
end

require File.dirname(__FILE__) + "/remoter_base"
