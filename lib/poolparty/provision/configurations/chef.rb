module PoolParty
  module Provision
    
    class Chef
      def self.commands
        [
          "/usr/bin/chef-solo -c /etc/chef/solo.rb -j /etc/chef/dna.json"
        ]
      end
      def self.files_to_upload
        [ "#{::File.dirname(__FILE__)}/../../templates/puppet/add_puppet_to_hosts",
          "#{::File.dirname(__FILE__)}/../../templates/puppet/puppet.conf",
          "#{::File.dirname(__FILE__)}/../../templates/puppet/puppetrunner",
          "#{::File.dirname(__FILE__)}/../../templates/puppet/site.pp" 
        ]
      end
    end
    
  end
end