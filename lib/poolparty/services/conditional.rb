module PoolParty
  def working_conditional
    @working_conditional ||= []
  end
  
  def case_of o, &block
    c = Conditional.new({:name => "case_of_#{o}", :attribute => o}, &block)
    add_service c
  end
  
  class Conditional < Service
    def initialize(opts={}, &block)      
      super(opts, &block)
    end
    
    def when_is o, &block
      add(o, &block)
    end  
    def otherwise &block
      add(nil, &block)
    end
    
    def add(o, &block)
      # proc = Proc.new do
        service = PoolParty::Service.new(&block)
        obj = (o ? o : :default).to_sym
        when_statements.merge!({o => service})
      # end
      # set_parent_and_eval(&proc)      
    end
    
    def when_statements
      @when_statement ||= {}
    end
    def to_properties_hash
      {
        :options => {:variable => self.attribute},
        :resources => {},
        :services => {:control_statements => when_statements}
      }
    end
  end
  
end