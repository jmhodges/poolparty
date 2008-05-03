require File.dirname(__FILE__) + '/helper'

context "with just instances" do
  setup do
    Coordinator.init
    Coordinator.shutdown_all!
  end
  specify "should be able to list the instance_names if empty" do
    Coordinator.instance_names.should be_empty
    Coordinator.instances.should be_empty
  end
  specify "should be able to add an instance" do    
    size = Coordinator.instances.size
    Coordinator.add!
    Coordinator.instance_names.should_not be_empty
    Coordinator.instances.size.should == size + 1
  end
  specify "should be able to remove an instance" do
    inst = Coordinator.add!
    size = Coordinator.instances.size
    Coordinator.remove! inst.instance_id
    Coordinator.instances.size.should == size - 1
    inst.stop!
  end
  specify "should be able to grab a random instance" do
    inst = Coordinator.add! "hoax"
    Coordinator.get_random_instance.should_not be_nil
  end
  specify "should be able to shutdown all the instances" do
    Coordinator.add!
    Coordinator.shutdown_all!
  end
end