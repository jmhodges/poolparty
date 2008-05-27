require File.dirname(__FILE__) + '/spec_helper'

describe "monitors" do
  it "should web monitor should be able to extract the amount of the requests it can handle" do
    str = "Request rate: 1.5 req/s (649.9 ms/req)"
    Monitors::Web.monitor_from_string(str).should == 1.5
  end
  it "should be able to monitor the percentage of memory available on the server" do
    str = "Mem:          1700         56       1644          0          2         18"
    Monitors::Memory.monitor_from_string(str).to_s.should =~ /0.032/
  end
  it "should be able to show the load on the cpu available on the server" do
    str = "18:55:31 up 5 min,  1 user,  load average: 0.32, 0.03, 0.00"
    Monitors::Cpu.monitor_from_string(str).should == 0.32
  end
end