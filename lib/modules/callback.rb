=begin rdoc
  Basic callbacks
=end
module PoolParty
  module Callbacks
    module ClassMethods      
      attr_reader :callbacks
      def define_callback_module(mod)
        callbacks << mod
      end
      def callback(type, m, *args, &block)
        arr = []
       
        args.each do |arg|
          arr << case arg.class.to_s
          when "Hash"
            arg.collect do |meth, klass|
              case klass.class.to_s
              when "String"
                # self => instance of callback from class
                # klass => class with callback
                "ubmeth = #{klass}.new.method(:#{meth}).to_proc                
                self.class.send :define_method, :#{meth} do
                  ubmeth.bind(self).call
                end
                instance = self
                #{klass}.class_eval do
                  def method_missing(name,*args) 
                    instance.send(name,*args)
                  end
                end
                # puts methods.sort - self.class.ancestors.first.methods
                #{meth}"
              else
                "#{klass}.send :#{meth}"
              end
            end
          when "Symbol"
            "#{arg}"            
          end
        end
        
        string = ""
        if block_given?
          num = store_proc(block.to_proc)
          arr << <<-EOM
            self.class.get_proc(#{num}).bind(self).call
          EOM
        end
        
        string = create_eval_for_mod_with_string_and_type!(m, type) do
          arr.join("\n")
        end        

        mMode = Module.new {eval string}

        define_callback_module(mMode)
      end
      def before(m, *args, &block)
        callback(:before, m, *args, &block)
      end
      def after(m, *args, &block)
        callback(:after, m, *args, &block)
      end
      
      def create_eval_for_mod_with_string_and_type!(meth, type=nil, &block)
        str = ""
        case type
        when :before          
          str << <<-EOD
            def #{meth}
              #{yield}
              super
            end
          EOD
        when :after
          str << <<-EOD
            def #{meth}
              super
              #{yield}
            end
          EOD
        else
          str << <<-EOD
            def #{meth}
              #{yield}
            end
          EOD
        end
        str
      end
      
      def callbacks
        @callbacks ||= []
      end
      
    end

    module InstanceMethods
      def initialize(*args)
        
        unless self.class.callbacks.empty?
          self.class.callbacks.each do |mod|
            self.extend(mod)
          end
        end
        
      end
    end
    
    module ProcStoreMethods
      def store_proc(proc)
        proc_storage << proc
        proc_storage.index(proc)
      end
      def get_proc(num)
        proc_storage[num]
      end
      def proc_storage
        @proc_store ||= []
      end
    end

    def self.included(receiver)
      receiver.extend         ClassMethods
      receiver.extend         ProcStoreMethods
      receiver.send :include, InstanceMethods
    end    
  end
  
end