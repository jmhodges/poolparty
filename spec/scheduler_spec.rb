require File.dirname(__FILE__) + '/spec_helper'

class TestSched  
  include Scheduler
end
describe "Scheduler" do
  before(:each) do
    @test = TestSched.new
  end
  it "should create a ScheduleTasks" do
    @test._tasker.class.should == ScheduleTasks
  end
  describe "run_thread_loop" do
    before(:each) do
      @klass = Class.new
      @klass.stub!(:pop).once.and_return true
      @block = Proc.new {@klass.pop}
    end
    it "should yield the block that it is given" do
      @test.run_thread_list &@block
    end
    it "should run run_threads" do
      @test.should_receive(:run_threads).and_return true
      @test.run_thread_list &@block
    end
    it "should call run on the _tasker" do
      @test._tasker.should_receive(:run).once.and_return true
      @test.run_thread_list &@block
    end
    describe "ScheduleTasks class" do
      before(:each) do
        @stasks = ScheduleTasks.new
        @test.stub!(:_tasker).and_return(@stasks)
      end
      it "should have its tasks listed as an empty array if there are no tasks added" do
        @stasks.tasks.should == []
      end
      it "should have one task listed if it is added" do
        @test.add_task {@klass.pop}        
        @stasks.tasks.size.should == 1
      end
      it "should add each task as a thread" do
        Thread.should_receive(:new).once
        @stasks.push proc{puts "hi"}
      end
    end
    describe "when running" do
      before(:each) do
        @test.add_task {@klass.pop}
      end
      it "should not run the tasks after adding them" do
        @klass.should_not_receive(:pop)
        @test.add_task {@klass.pop}
      end
      it "should run the tasks when run_thread_list" do
        @klass.should_receive(:pop)
        @test.run_thread_list
      end
      it "should be able to add tasks and have the run_thread_list run" do
        @test._tasker.class.should_receive(:synchronize).once        
        @test.run_thread_list
      end
      it "should empty all the tasks after running them in the loop" do
        @test.run_thread_list
        @test._tasker.tasks.size.should == 0
      end
      describe "daemonizing" do
        it "should detached the process" do
          Process.should_receive(:detach).once
          @test.daemonize
        end
      end
    end
  end
end