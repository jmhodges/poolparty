module PoolParty
  def working_conditional
    @working_conditional ||= []
  end
  
  def case_of o
    c = Conditional.new(:name => "case_of_#{o}", :attribute => o)
    working_conditional.push c
  end  
  def when_is o, &block
    working_conditional.last.add(o, &block)
  end  
  def otherwise &block
    working_conditional.last.add(nil, &block)
  end
  def end_of
    working_conditional.last.options.freeze
    add_service working_conditional.last
  end
  
  class Conditional < Service
    def initialize(opts={}, &block)      
      super(opts, &block)
    end
    
    def add(o, &block)
      proc = Proc.new do
        service = PoolParty::Service.new(&block)
        when_statements << {(o ? o : :otherwise).to_sym, service}
      end
      set_parent_and_eval(&proc)      
    end
    
    def when_statements
      @when_statement ||= []
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