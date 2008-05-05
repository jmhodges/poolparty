module PoolParty
  extend self
  
  module Ec2Wrapper
    module ClassMethods
      
    end
    
    module InstanceMethods
      # Run a new instance, with the user_data and the ami described in the config
      def launch_new_instance!
        ec2.run_instances(:image_id => ami, :user_data => "#{Application.user_data}")
      end
      # Shutdown the instance by instance_id
      def terminate_instance!(instance_id)
        ec2.terminate_instances(:instance_id => instance_id)
      end
      
      def get_instances_description
        return begin
          ec2.describe_instances.DescribeInstancesResponse.reservationSet.item.collect {|r| 
            item = r.instancesSet.item
            {:id => item.instanceId, :ip => item.dnsName, :status => item.instanceState.name} }
        rescue Exception => e
          []
        end      
      end
      
      # EC2 connections
      def ec2
        @ec2 ||= EC2::Base.new(:access_key_id => access_key_id, :secret_access_key => secret_access_key)
      end
      
    end
    
    def self.included(receiver)
      receiver.extend         ClassMethods
      receiver.send :include, InstanceMethods
    end
  end
end