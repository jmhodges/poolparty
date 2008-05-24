module PoolParty
  module Os    
    module Ubuntu
      def install_stack
        install_haproxy
        install_heartbeat
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
          apt-get -y install monit
          mkdir /etc/monit
        EOC
        ssh cmd.runnable
      end
      def install_nginx
        cmd=<<-EOC
          apt-get -y install nginx
        EOC
        ssh cmd.runnable
      end
      def install_heartbeat
        cmd=<<-EOC
          apt-get -y install heartbeat-2
        EOC
        ssh cmd.runnable
      end
      def install_s3fuse
        cmd=<<-EOC
          cd /usr/local/src
          apt-get -y install build-essential libcurl4-openssl-dev libxml2-dev libfuse-dev 
          wget http://s3fs.googlecode.com/files/s3fs-r166-source.tar.gz
          tar -zxf s3fs-r166-source.tar.gz
          cd s3fs/
          make
          ln -s /usr/local/src/s3fs/s3fs /usr/bin
        EOC
        ssh cmd.runnable
      end
    end
    
  end
end