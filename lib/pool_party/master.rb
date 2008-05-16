module PoolParty
  class Master < Remoting
    attr_accessor :master, :slaves
    
    def start!
      launch_minimum_instances
    end
    
    def start_cloud!
      message "Starting cloud"
      launched = start!

      @master, @slaves = launched.shift, launched

      message "MASTER INSTANCE ID: #{master.instance_id}"
      slaves.each do |slave|
        message "-- slave instance id: #{slave.instance_id}"
      end      
    end
    
    def list_cloud
      msg=<<-EOM
------------------- CLOUD -------------------
Number of instances = #{number_of_pending_and_running_instances}
---------------------------------------------
------- MASTER: #{master.ip}
#{slaves.collect do |slave|
"------- SLAVE: #{slave.ip}"
end}
---------------------------------------------
      EOM
      message msg
    end
    
    def launch_minimum_instances
      request_launch_new_instances(Application.minimum_instances - number_of_pending_and_running_instances).collect do |inst|
        RemoteInstance.new(inst)
      end
    end
    
    def master;@master;end
    def slaves;@slaves;end
    
  end
end