module PoolParty
  
  class Service < PoolPartyBaseClass
    
    def initialize(o={}, &block)
      super(o, &block)
    end
    
    def cloud
      2.upto(context_stack.size) do |i|
        return ::PoolParty.context_stack[-i] if ::PoolParty.context_stack[-i].is_a?(PoolParty::Cloud::Cloud)
      end
      nil
    end
    
    def self.add_has_and_does_not_have_methods_for(type=:file)
      lowercase_class_name = type.to_s.top_level_class.downcase
      
      meth = <<-EOM
        def #{lowercase_class_name}(opts={}, &block)
          PoolParty::#{lowercase_class_name.camelcase}Class.new(opts, &block)
        end
      EOM
      
      PoolParty::PoolPartyBaseClass.module_eval meth
      PoolParty::PoolPartyBaseClass.add_has_and_does_not_have_methods_for(lowercase_class_name.to_sym)
    end
    
  end
  
end

Dir["#{::File.dirname(__FILE__)}/../services/*.rb"].each {|lib| require "#{lib}"}