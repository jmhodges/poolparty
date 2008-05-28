module PoolParty
  module EC2Mock
    def launch_new_instance!
      letter = ("a".."z").to_a[instances.size] # For unique instance_ids
      h = {:instance_id => "i-58ba56#{letter}", :ip => "ip-127-0-0-1.aws.amazonaws.com", :status => "pending", :launching_time => Time.now }
      instances << h      
      Thread.new {wait 0.1;h[:status] = "running"} # Simulate the startup time
      return h
    end
    # Shutdown the instance by instance_id
    def terminate_instance!(instance_id)
      instances.select {|a| a[:instance_id] == instance_id}[0][:status] = "terminating"
    end
    # Instance description
    def describe_instance(id)
      item = instances.select {|a| a[:instance_id] == id}[0]
      EC2ResponseObject.get_hash_from_response(item)
    end
    # Get instance by id
    def get_instance_by_id(id)
      get_instances_description.select {|a| a.instance_id == id}[0] rescue nil
    end
    # Get the s3 description for the response in a hash format
    def get_instances_description
      instances
    end
    # Fake the ec2 connection
    def ec2
      @ec2 ||= EC2::Base.new(:access_key_id => "not a key", :secret_access_key => "not a key")
    end
    # Some basic instances, not totally necessary
    def instances
      @instances ||= []
    end
  end
  class EC2ResponseObject
    def self.get_descriptions(resp)
      rs = resp.DescribeInstancesResponse.reservationSet.item
      rs = rs.respond_to?(:instancesSet) ? rs.instancesSet : rs
      out = begin
        rs.reject {|a| a.empty? }.collect {|r| EC2ResponseObject.get_hash_from_response(r.instancesSet.item)}.reject {|a| a.nil?  }
      rescue Exception => e
        begin
          # Really weird bug with amazon's ec2 gem
          rs.reject {|a| a.empty? }.collect {|r| EC2ResponseObject.get_hash_from_response(r)}.reject {|a| a.nil?  }
        rescue Exception => e
          []
        end                
      end
      out
    end
    def self.get_hash_from_response(resp)
      {:instance_id => resp.instanceId, :ip => resp.dnsName, :status => resp.instanceState.name, :launching_time => resp.launchTime} rescue nil
    end
  end
end