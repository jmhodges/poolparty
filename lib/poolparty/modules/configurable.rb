#TODO: rdoc: this  defines methods on poolparty objects from a passed hash of options.
# For example, this is how instance.minimum_runtime is set.  See base.rb line 12 for example of default options that are added as methods in this way. 
module PoolParty
  module Configurable
    module ClassMethods
      
      # Provides a class options hash to hold the values that will be set by define_defaults
      def class_defaults(h={})
        @defaults ||= h
      end
      
      def default_options(h={})
        define_defaults(h)
        # @default_options ||= h.each do |k,v|
        #   module_eval "def #{k}(i=nil); i ? options[:#{k}] = i : options[:#{k}]; end"
        #   module_eval "def #{k}=(v);options[:#{k}]=v;end"
        # end
      end
      
      def define_defaults(ops={})
        ops.each do |k, v|
          next if k.to_s == 'options'
          class_defaults[k.to_sym] = v
          methods_to_define = {
            :class_getter => "class << self; def #{k}; class_defaults[:#{k}]; end; end",
            :instance_get_and_set => "def #{k}(i=nil); i ? @#{k} = i : @#{k}; end",
            :instance_set_with_eql => "def #{k}=(v); @#{k}=v;end",
          }.each {|method, definition| module_eval definition}
        end
      end

      # try it using instance variables
      # def define_defaults(ops={})
      #   ops.each do |k, v|
      #     next if k.to_s == 'options'
      #     # class_defaults[k.to_sym] = v
      #     puts "setting self #{k} = #{v}"
      #     instance_variable_set "@#{k}", v
      #     methods_to_define = {
      #       :attr_accessor => "attr_accessor :#{k}",
      #       :class_getter => "class << self; def #{k}; @#{k}; end; end"
      #     }.each {|method, definition| module_eval definition}
      #     puts " #{self} @minimum_instances= #{@minimum_instances}" if k.to_s =~ /minimum_run/
      #   end
      # end
      
      def dsl_accessors(arr=[])
        @dsl_accessors ||= arr.map do |acc|
          class_eval "def #{acc}(i=nil); i ? options[:#{acc}] = i : options[:#{acc}]; end;def #{acc}=(v);options[:#{acc}]=v;end"
          acc
        end
      end
    end
    
    module InstanceMethods
      def options(h={})
        puts "calling options from #{self} #{caller[0]}"
        __options(h)
      end
      def __options(h={})
        # @options ||= self.class.default_options.merge(h)
        @__options ||= self.class.class_defaults
      end
      
      def dsl_accessors
        @dsl_accessors ||= set_dsl_accessors
      end
      
      def set_dsl_accessors
        self.class.dsl_accessors
      end
      
      def configure(h={})
        options.merge!(h)
      end
      
      def reconfigure(h={})
        @options = nil
        options(h)
      end
      
      def []=(k,v)
        options[k] = v
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