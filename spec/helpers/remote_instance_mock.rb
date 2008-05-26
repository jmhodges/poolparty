module PoolParty
  module RemoteInstanceMock
    def scp(src="", dest="")
      true
    end
    # Ssh into the instance or run a command, if the cmd is set
    def ssh(cmd="")
      true
    end
  end
end