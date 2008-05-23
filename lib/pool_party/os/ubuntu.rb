module PoolParty
  module Os    
    module Ubuntu
      def install_stack
        install_haproxy
        install_monit
      end
      def install_haproxy
        cmd <<-EOC
          apt-get install monit
          mkdir /etc/monit
        EOC
        ssh cmd.runnable
      end
      def install_monit
        cmd <<-EOC
          apt-get install haproxy
          rm /etc/haproxy.cfg
        EOC
        ssh cmd.runnable
      end
      def install_nginx
        cmd <<-EOC
          apt-get install nginx
        EOC
        
        ssh cmd.runnable
      end
    end
    
  end
end