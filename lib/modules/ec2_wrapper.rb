module PoolParty
  extend self
  
  module Ec2Wrapper
    
    module ClassMethods      
    end
    
    module InstanceMethods
      # Run a new instance, with the user_data and the ami described in the config
      def launch_new_instance!
        instance = ec2.run_instances(
          :image_id => Application.ami, 
          :user_data => "#{Application.launching_user_data}",
          :minCount => 1,
          :maxCount => 1,
          :key_name => Application.keypair,
          :size => "#{Application.size}")
          
        item = instance.RunInstancesResponse.instancesSet.item
        EC2ResponseObject.get_hash_from_response(item)
      end
      # Shutdown the instance by instance_id
      def terminate_instance!(instance_id)
        ec2.terminate_instances(:instance_id => instance_id)
      end
      # Instance description
      def describe_instance(id)
        instance = ec2.describe_instances(:instance_id => id)
        item = instance.DescribeInstancesResponse.reservationSet.item.instancesSet.item
        EC2ResponseObject.get_hash_from_response(item)
      end
      # Get instance by id
      def get_instance_by_id(id)
        get_instances_description.select {|a| a.instance_id == id}[0] rescue nil
      end
      # Get the s3 description for the response in a hash format
      def get_instances_description
        EC2ResponseObject.get_descriptions(ec2.describe_instances)
        # begin
        #   # FIX ME
        #   ec2.describe_instances.DescribeInstancesResponse.reservationSet.item.collect {|r|
        #     item = r.instancesSet.item; EC2ResponseObject.get_hash_from_response(item) }
        # rescue Exception => e
        #   puts "Error: #{e}"
        #   []
        # end
      end
      
      # EC2 connections
      def ec2
        @ec2 ||= EC2::Base.new(:access_key_id => Application.access_key_id, :secret_access_key => Application.secret_access_key)
      end      
    end
    
    def self.included(receiver)
      receiver.extend         ClassMethods
      receiver.send :include, InstanceMethods
    end
  end
  class EC2ResponseObject
    def self.get_descriptions(resp)
      rs = resp.DescribeInstancesResponse.reservationSet
      out = begin
        if rs.respond_to?(:instancesSet)
          rs.instancesSet.item.collect {|r| EC2ResponseObject.get_hash_from_response(r.item)}
        else
          rs.item.collect {|r| EC2ResponseObject.get_hash_from_response(r.instancesSet.item)}
        end
      rescue Exception => e
        []
      end
      out
    end
    def self.get_hash_from_response(resp)
      {:instance_id => resp.instanceId, :ip => resp.dnsName, :status => resp.instanceState.name} rescue {}
    end
  end
end