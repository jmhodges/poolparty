# STUB FOR NOW
# TODO
module PoolParty
  class Key
    
    attr_reader :filepath
    
    def initialize(filepath=nil)
      @filepath = filepath
    end
    
    def full_filepath
      @filepath
    end
    
  end
end