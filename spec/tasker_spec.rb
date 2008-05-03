require File.dirname(__FILE__) + '/helper'

context "Upon starting" do
  setup do
    @tasker = Tasker.new
  end
  specify "should be able to load" do
    @tasker.should_not be_nil
  end
  specify "should be able to view the work queue" do
    @tasker.work_queue.should_not be_nil
  end
  specify "should be able to view the status queue" do
    @tasker.status_queue.should_not be_nil
  end
end