require "#{File.dirname(__FILE__)}/spec_helper"

describe "local instance" do
  before(:each) do
    
    conf = {"port" => 7788, "interval" => 30}.to_yaml
    URI.stub!(:parse).with("http://169.254.169.254/latest/user-data").and_return(conf)
        
    @instance = LocalInstance.new
    @instance.stub!(:start_monitors!).and_return(true)
    @instance.stub!(:start_server!).and_return(true)
    @instance.stub!(:cpu).and_return(0.14)
    @instance.stub!(:memory).and_return(0.74)
    @instance.stub!(:web).and_return(120.0)
    
    Monitors::Cpu.stub!(:monitor!).and_return("0.14")
    Monitors::Memory.stub!(:monitor!).and_return("0.74")
    Monitors::Web.stub!(:monitor!).and_return("120.0")    
  end
  
  describe "with services on startup" do
    it "should start_monitors! when started" do
      @instance.should_receive(:start_monitors!).and_return(true)
      @instance.start!
    end
    it "should start_server! when started" do
      @instance.should_receive(:start_server!).and_return(true)
      @instance.start!
    end
  end
  
  describe "when updating monitors" do
    it "should call update on CPU when called" do
      Monitors::Cpu.should_receive(:monitor!).and_return("0.14")
      @instance.update_monitors
    end
    it "should call update on Memory when called" do
      Monitors::Memory.should_receive(:monitor!).and_return("0.14")
      @instance.update_monitors
    end
    it "should call update on Web when called" do
      Monitors::Web.should_receive(:monitor!).and_return("0.14")
      @instance.update_monitors
    end
  end
  
  describe "status updater" do
    it "should return the status as a string from yaml" do
      YAML.load(@instance.status).should == {"cpu" => 0.14, "memory" => 0.74, "web" => 120.0}
    end
    it "should load the config from the user-data" do
      @instance.config.should_not be_nil
    end
  end
  
end