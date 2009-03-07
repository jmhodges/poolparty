#TODO: rdoc: this  defines methods on poolparty objects from a passed hash of options.
# For example, this is how instance.minimum_runtime is set.  See base.rb line 12 for example of default options that are added as methods in this way. 
module PoolParty
  module Configurable
    module ClassMethods      
      def default_options(h={})
        @default_options ||= h
      end
      def dsl_accessors(arr=[])
        @dsl_accessors ||= arr.map do |acc|
          class_eval "def #{acc}(i=nil); i ? options[:#{acc}] = i : options[:#{acc}]; end;def #{acc}=(v);options[:#{acc}]=v;end"
          acc
        end
      end
    end
    
    module InstanceMethods
      def options(h={})
        @options ||= self.class.default_options.merge(h)
      end
      
      def dsl_accessors
        @dsl_accessors ||= set_dsl_accessors
      end
      
      def set_dsl_accessors
        self.class.dsl_accessors
      end
      
      def configure(h={})
        options(h).merge!(h)
      end
      
      def reconfigure(h={})
        @options = nil
        options(h)
      end
      
      def set_vars_from_options(opts={})
        opts.each {|k,v| self.send k.to_sym, send_if_method(v) } unless opts.empty?
      end
    end
    
    def self.included(receiver)
      receiver.extend         ClassMethods
      receiver.send :include, InstanceMethods
      receiver.send :include, MethodMissingSugar
    end
  end
end