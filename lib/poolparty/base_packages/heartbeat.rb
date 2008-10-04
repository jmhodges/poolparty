module PoolParty
  class Base
    plugin :heartbeat do
      
      def enable
        has_package(:name => "heartbeat-2", :ensure => "running")
        has_service(:name => "heartbeat", :hasstatus => true) do
          ensures "running"
        end
        
        has_exec(:name => "heartbeat-update-cib", :command => "/usr/sbin/cibadmin -R -x /etc/ha.d/cib.xml", :refreshonly => true)
        
        # variables for the templates
        has_variable({:name => "nodenames", :value => list_of_node_names})
        has_variable({:name => "node_ips",  :value => list_of_node_ips})
        has_variable({:name => "port", :value => (port || Base.port)})
        
        # These can also be passed in via hash
        has_remotefile(:name => "/etc/ha.d/ha.cf") do
          mode 444
          requires 'Package["heartbeat-2"]'
          notify 'Service["heartbeat"]'
          template File.join(File.dirname(__FILE__), "..", "templates/ha.cf"), {:just_copy => true, :path => "/etc/ha.d"}
        end
        
        has_remotefile(:name => "/etc/ha.d/authkeys") do
          mode 400
          requires 'Package["heartbeat-2"]'
          notify 'Service["heartbeat"]'
          template File.join(File.dirname(__FILE__), "..", "templates/authkeys"), {:just_copy => true,:path => "/etc/ha.d"}
        end
        
        has_remotefile(:name => "/etc/ha.d/cib.xml") do
          mode 444
          requires 'Package["heartbeat-2"]'
          notify 'Exec["heartbeat-update-cib"]'
          template File.join(File.dirname(__FILE__), "..", "templates/cib.xml"), {:just_copy => true, :path => "/etc/ha.d"}
        end                
        
      end
    end  
  end
end