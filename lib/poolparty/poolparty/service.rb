module PoolParty
  
  class Service < PoolPartyBaseClass
    
    def initialize(&block)
      # FIXME -> make pretty
      puts "parent for #{self}: #{parent}"
      super(parent, &block)
    end
    
    
    def self.add_has_and_does_not_have_methods_for(type=:file)
      lowercase_class_name = type.to_s.top_level_class.downcase
      
      meth = <<-EOM
        def #{lowercase_class_name}(opts={}, &block)
          PoolParty::#{lowercase_class_name.camelcase}Class.new(opts, &block)
        end
      EOM
      
      PoolParty::Resources.module_eval meth
      PoolParty::Resources.add_has_and_does_not_have_methods_for(lowercase_class_name.to_sym)
    end
    
  end
  
end