require File.dirname(__FILE__) + '/helper'

context "on the server" do
  setup do
    @attendee = Attendee.new :dont_run => true
  end
  specify "should be able to find out the current load" do
    @attendee.current_load.should_not be_nil
    @attendee.shutdown!
  end
  
  specify "should start a daemon" do
    size = `ps aux | grep ruby | wc -l | awk '{print $1}'`
    @attendee.monitor!
    new_size = `ps aux | grep ruby | wc -l | awk '{print $1}'`
    new_size.to_i.should == size.to_i + 1    
    @attendee.shutdown!
  end
end