$:.unshift(File.dirname(__FILE__))
require "backcall"
require "remoter"
class Test
  include PoolParty::Remoter
  include Callbacks
  
  after :initialize, :set_hosts
  def rt
    @rt ||= Rake::RemoteTask
  end
  
  def set_hosts(c)
    rt.host "myslice", :app, :db
  end
  
  def rtask(name, *args, &block)
    rt.remote_task(name.to_sym => args, &block)
  end
    
  def scp local, remote
    require "tempfile"
    rtask(:scp) do
      put remote do
        open(local).read
      end
    end.execute
  end
  before :scp, :set_hosts
  def ssh command=nil, &block
    block = Proc.new do
      run command
    end
    rtask(:ssh, &block).execute
  end
  before :ssh, :set_hosts
end

t = Test.new
t.scp("/Users/auser/Sites/work/citrusbyte/internal/gems/pool-party/pool/CHANGELOG", "ho")
t.ssh("ls -l")
t.ssh <<-EOE
  ls -l
  mv ho CHANGELOG
  cat CHANGELOG
EOE