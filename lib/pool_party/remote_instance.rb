module PoolParty
  class RemoteInstance
    attr_reader :load, :updated_time, :ip, :key
    
    def initialize(obj)
      @key = obj.key
      begin
        @ip = obj.value.split("\n")[0]
        @load = obj.value.split("\n")[1]
        @updated_time = obj.value.split("\n")[2]
      rescue Exception => e
      end
    end
    
  end
end