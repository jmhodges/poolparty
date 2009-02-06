require File.dirname(__FILE__) + "/remoter"

module PoolParty  
  module Remote
    
    # RemoteInstance contains methods and properties appropriate for a single instance of a remoter base cloud.  Remote instances of supported rmoterbases should inherit from this class, and override as necessary.
    class RemoteInstance #< RemoterBase
      include Configurable
      include CloudResourcer
      
      
      def initialize(opts, parent=self)
        @uniquely_identifiable_by = [:instance_id, :ip, :name ] if !@uniquely_identifiable_by
        if !opts.keys.detect{|k| @uniquely_identifiable_by.include?(k) }
          raise "You must pass at least on key=>value pair that will uniquely identify an instance. Possible keys are #{@uniquely_identifiable_by.inspect}." 
        end
        run_setup(parent)
        set_vars_from_options(parent.options) if parent && parent.respond_to?(:options)
        set_vars_from_options(opts) unless opts.nil? || opts.empty?
        on_init
      end
      
      def elapsed_runtime
        Time.now.to_i - launching_time.to_time.to_i
      end
      
      # Callback
      def on_init
      end
      
      # Is this remote instance the master?
      # DEPRECATE
      def master?
        name == "master"
      end
      
      # The remote instances is only valid if there is an ip and a name
      def valid?
        (ip.nil? || name.nil?) ? false : true
      end
      
      # Determine if the RemoteInstance is responding
      def responding?
        running?
        # !responding.nil? #TODO MF this needs to actually ping the node or something similar.  stubbed to running? for now
      end
      
      # This is how we get the current load of the instance
      # The approach of this may change entirely, but the usage of
      # it will always be the same
      def load
        current_load ||= 0.0  #NOTE MF: returning 0.0 seems like a bad idea here.  should return nil if we dont have a real value
      end
            
      # Is this instance running?
      def running?
        !(status =~ /running/).nil?
      end
      # Is this instance pending?
      def pending?
        !(status =~ /pending/).nil?
      end
      # Is this instance terminating?
      def terminating?
        !(status =~ /shutting/).nil?
      end
      # Has this instance been terminated?
      def terminated?
        !(status =~ /terminated/).nil?
      end
      
      # Printing. This is how we extract the instances into the listing on the 
      # local side into the local listing file
      def to_s
        "#{name}\t#{ip}\t#{instance_id}"
      end
      
      def puppet_runner_command
        self.class.send :puppet_runner_command
      end
      # Commands for the servers
      def self.puppet_runner_command
        ". /etc/profile && puppetrunner"
      end
      def self.puppet_master_rerun_command
        ". /etc/profile && puppetrerun"
      end
      def self.puppet_rerun_commad
        puppet_runner_command
      end
      def my_cloud
        @pa = parent
        while !(@pa.is_a?(PoolParty::Cloud::Cloud) || @pa.nil? || @pa == self)
          @pa = @pa.parent
        end
        @pa
      end
      def hosts_file_listing_for(cl)
        string = (cl.name == cloud.name) ? "#{name}.#{my_cloud.name}\t#{name}" : "#{name}.#{my_cloud.name}"
        "#{internal_ip}\t#{string}"
      end
    end
    
  end  
end