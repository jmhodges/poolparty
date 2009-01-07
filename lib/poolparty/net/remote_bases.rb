module PoolParty  
  module Remote
    # Register the remoter base in the remote_bases global store
    def self.register_remote_base(*args)
      args.each do |arg|
        base_name = "#{arg}".downcase.to_sym
        (remote_bases << base_name) unless remote_bases.include?(base_name)
      end
    end

    def self.remote_bases
      $remote_bases ||= []
    end
    
    class RemoteBases < Remote      

      def using(t)
        @cloud = self
        if t && available_bases.include?(t.to_sym)
          unless using_remoter?
            self.class.send :attr_reader, :remote_base
            self.class.send :attr_reader, :parent_cloud
            
            klass = "#{t}".class_constant(self.constantize, :preserve => true)
            @remote_base = klass.send :new
            @parent_cloud = @cloud
          end
        else
          puts "Unknown remote base" 
        end
      end

      def available_bases
        remote_bases
      end

      def using_remoter?
        @remote_base ||= nil
      end
    end                
  end  
end