module PoolParty
  module Os    
    module Ubuntu
      def install_stack
        install_haproxy
        install_monit
      end
      def install_haproxy
        cmd=<<-EOC
          apt-get install haproxy
          sed -i 's/ENABLED=0/ENABLED=1/g' /etc/default/haproxy
          sed -i 's/SYSLOGD=\"\"/SYSLOGD=\"-r\"/g' /etc/default/syslogd
          echo 'local0.* /var/log/haproxy.log' >> /etc/syslog.conf && killall -9 syslogd && syslogd
        EOC
        ssh cmd.runnable
      end
      def install_monit
        cmd=<<-EOC
          apt-get install monit
          mkdir /etc/monit
        EOC
        ssh cmd.runnable
      end
      def install_nginx
        cmd=<<-EOC
          apt-get install nginx
        EOC
        ssh cmd.runnable
      end
    end
    
  end
end