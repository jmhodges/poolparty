module PoolParty
  module RemoteInstanceMock
    def scp(src="", dest="")
      "true"
    end
    def ssh(cmd="")
      puts "In RemoteInstanceMock: ssh"
      "true"
    end
  end
end