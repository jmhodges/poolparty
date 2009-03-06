module PoolParty
  
  class Service < PoolPartyBaseClass
    
    def initialize(&block)
      super(parent, &block)
    end
    
    
    def self.add_has_and_does_not_have_methods_for(type=:file)
      # PoolParty::Resources.add_has_and_does_not_have_methods_for(lowercase_class_name.to_sym)
      module_eval <<-EOE
        def has_#{type}(opts={}, extra={}, &block)
          #{type}(handle_option_values(opts).merge(extra.merge(:ensures => "present")), &block)
        end
        def does_not_have_#{type}(opts={}, extra={}, &block)
          #{type}(handle_option_values(opts).merge(extra.merge(:ensures => "absent")), &block)
        end
      EOE
    end
    
  end
  
end