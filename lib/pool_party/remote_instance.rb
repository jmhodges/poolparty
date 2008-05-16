module PoolParty
  class RemoteInstance
    attr_reader :ip, :instance_id
    
    def initialize(obj)
      @ip = obj[:ip]
      @instance_id = obj[:instance_id]
    end

  end
end