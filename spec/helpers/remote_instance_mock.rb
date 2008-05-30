module PoolParty
  module RemoteInstanceMock
    def scp(src="", dest="")
      "true"
    end
    def ssh(cmd="")
      "true"
    end
  end
end