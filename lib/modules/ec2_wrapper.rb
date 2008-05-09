module PoolParty
  extend self
  
  module Ec2Wrapper
    
    module ClassMethods      
    end
    
    module InstanceMethods
      # Run a new instance, with the user_data and the ami described in the config
      def launch_new_instance!
        instance = ec2.run_instances(:image_id => Application.ami, :user_data => "#{Application.launching_user_data}")
        item = instance.RunInstancesResponse.instancesSet.item
        get_hash_from_response(item)
      end
      # Shutdown the instance by instance_id
      def terminate_instance!(instance_id)
        ec2.terminate_instances(:instance_id => instance_id)
      end
      # Instance description
      def describe_instance(id)
        instance = ec2.describe_instances(:instance_id => id)
        item = instance.DescribeInstancesResponse.reservationSet.item.instancesSet.item
        get_hash_from_response(item)
      end
      # Get instance by id
      def get_instance_by_id(id)
        get_instances_description.select {|a| a.instance_id == id}[0] rescue nil
      end
      # Get the s3 description for the response in a hash format
      def get_instances_description
        begin
          ec2.describe_instances.DescribeInstancesResponse.reservationSet.item.collect {|r| 
            item = r.instancesSet.item; get_hash_from_response(item) }
        rescue Exception => e
          []
        end
      end
      
      # EC2 connections
      def ec2
        @ec2 ||= EC2::Base.new(:access_key_id => Application.access_key_id, :secret_access_key => Application.secret_access_key)
      end
      
      private
      def get_hash_from_response(resp)
        {:instance_id => resp.instanceId, :ip => resp.dnsName, :status => resp.instanceState.name}
      end      
    end
    
    def self.included(receiver)
      receiver.extend         ClassMethods
      receiver.send :include, InstanceMethods
    end
  end
end