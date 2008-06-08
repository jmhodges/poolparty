require File.dirname(__FILE__) + '/spec_helper'

describe "Deployer class" do
  before(:each) do
    @master = Master.new
    @master.stub!(:list_of_nonterminated_instances).and_return(
    [{:instance_id => "i-5849ba", :ip => "ip-127-0-0-1.aws.amazon.com", :status => "running"}])
  end
  it "should be able to set the roles for instances" do
    Deployer.set_roles_for_instances_as(@master.nodes)
    Deployer.roles.should == ["role :app, 'ip-127-0-0-1.aws.amazon.com'"]
  end
  describe "installing" do
    before(:each) do
      Deployer.reset
      Deployer.set_roles_for_instances_as(@master.nodes)
    end
    it "should call Sprinkle::Script when running the installation" do      
      Sprinkle::Script.should_receive(:sprinkle).and_return true
      Deployer.install_on_roles
    end
    it "should deploy" do
      lambda {
        Deployer.install_on_roles
      }
    end
  end
end