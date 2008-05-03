require File.dirname(__FILE__) + '/helper'

class TestLiveExtsClass
  include LiveExts
end

context "time to update" do
  setup do
    @tklass = TestLiveExtsClass.new
  end
  specify "should be able to tell that the time has not passed and it is not time to update" do    
    @tklass.update_checked_time
    @tklass.time_to_update?.should == false
  end
  specify "should be able to tell that it has been more than enough time and it should update" do
    @tklass.update_checked_time(50.days.ago)
    @tklass.time_to_update?.should == true
  end
end
context "run_and_update_if_time_to_run" do
  setup do
    @tklass = TestLiveExtsClass.new
    @first_nil = nil    
  end
  specify "should run but not update" do
    @tklass.update_checked_time
    @tklass.run_and_update_if_time_to_run(@first_nil) do
      @first_nil = "hi"
    end.should == nil
  end
  specify "should run and update after the amount of time has passed that it should" do
    @tklass.update_checked_time(5.days.ago)
    @tklass.run_and_update_if_time_to_run(@first_nil) do
      @first_nil = "hi"
    end.should == @first_nil
    @first_nil.should_not be_nil
  end
end
context "with threads" do
  setup do
    @tklass = TestLiveExtsClass.new
    @message = ""
  end
  specify "should be able to add to the threads, but not call it" do
    @message.should_not == "hello"
    @tklass.add_thread {@message << "hello"}
    @tklass.run_threads
    @message.should == "hello"
  end
  specify "should be able to run the threads" do
    @message.should_not == "hello world"
    @tklass.add_thread {@message = "hello"}
    @tklass.add_thread {@message << " "}
    @tklass.add_thread {@message << "world"}        
    @tklass.run_threads
    @message.should == "hello world"
  end
  specify "should be able to run the long threads as well" do
    @tklass.add_thread {sleep 2; @message << "after 2 "}
    @tklass.add_thread {sleep 1; @message << "after 1"}
    @tklass.run_threads
    @message.should == "after 2 after 1"
  end
end