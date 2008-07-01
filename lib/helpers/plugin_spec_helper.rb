module PoolParty
  class PluginSpecHelper
    def self.define_stubs(klass, num=1)
      require File.dirname(__FILE__) + "/../../spec/helpers/ec2_mock"
      
      @klass = klass.send :new
      klass.stub!(:new).and_return @klass
      extend_klass(@klass)
      
      define_master
      @nodes = define_instances(num)

      @master.stub!(:execute_tasks).and_return true
      @master.stub!(:launch_minimum_instances).and_return true
      @master.stub!(:number_of_pending_instances).and_return 0
      @master.stub!(:get_node).with(0).and_return @instance0

      @master.stub!(:nodes).and_return @nodes

      Kernel.stub!(:system).and_return "true"

      Provider.stub!(:install_poolparty).and_return true
      Provider.stub!(:install_userpackages).and_return true

      [@klass, @master, @nodes]
    end
    def self.extend_klass(klass)
      klass.class.send :define_method, :testing do |except|
        (klass.my_methods).each do |meth|
          klass.stub!(meth.to_sym).and_return true
        end
      end
    end
    def self.define_master
      @master ||= Master.new
    end
    def self.define_instances(num)
      # Too many gross evals
      returning [] do |arr|
        num.times do |i|
          eval <<-EOE
            @instance#{i} = RemoteInstance.new
            @instance#{i}.stub!(:ssh).and_return "true"
            @instance#{i}.stub!(:scp).and_return "true"
            @instance#{i}.stub!(:name).and_return "node#{i}"
            @instance#{i}.stub!(:ip).and_return "127.0.0.#{i}"
          EOE
          arr << eval("@instance#{i}")
        end
      end
    end
  end
end