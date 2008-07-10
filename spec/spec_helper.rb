lpwd = File.dirname(__FILE__)
$:.unshift(lpwd)
require File.join(lpwd, *%w[.. lib poolparty])

%w(spec).each do |library|
  begin
    require library
  rescue
    STDERR.puts "== Cannot run test without #{library}"
  end
end

Dir["#{File.dirname(__FILE__)}/helpers/**"].each {|a| require a}

include PoolParty
extend PoolParty

Application.environment = "test"
Application.verbose = false

def stub_option_load
    @str=<<-EOS
:access_key:    
  3.14159
:secret_access_key:
  "pi"
    EOS
    @sio = StringIO.new
    StringIO.stub!(:new).and_return @sio
    Application.stub!(:open).with("http://169.254.169.254/latest/user-data").and_return @sio
    @sio.stub!(:read).and_return @str
    PoolParty.stub!(:timer).and_return Timeout
    PoolParty.timer.stub!(:timeout).and_return lambda {YAML.load(open("http://169.254.169.254/latest/user-data").read)}
    Application.reset!
end

def wait_launch(time=5)
  pid = fork {yield}
  wait time
  Process.kill("INT", pid)
  Process.wait(pid, 0)
end