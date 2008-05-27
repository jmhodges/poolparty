require File.dirname(__FILE__) + '/spec_helper'

describe "monitors" do
  it "should web monitor should be able to extract the amount of the requests it can handle" do
    str = "Request rate: 1.5 req/s (649.9 ms/req)"
    Monitors::Web.monitor_from_string(str).should == 1.5
  end
end