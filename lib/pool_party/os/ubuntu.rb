=begin rdoc
  Ubuntu specific install tasks for PoolParty
=end
module PoolParty
  module Os    
    module Ubuntu
      def install_stack
        install_haproxy
        install_heartbeat
        install_monit
        install_s3fuse
      end
      def install_haproxy
        cmd=<<-EOC
          apt-get -y install haproxy
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
          sed -i 's/startup=0/startup=1/g' /etc/default/monit
          /etc/init.d/monit start
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
          cd /usr/local/src && wget http://s3fs.googlecode.com/files/s3fs-r166-source.tar.gz 
          tar -zxf s3fs-r166-source.tar.gz
          cd s3fs/ && make
          mv s3fs /usr/bin
          mkdir /data
        EOC
        ssh("apt-get -y install build-essential libcurl4-openssl-dev libxml2-dev libfuse-dev")
        ssh(cmd.runnable)
      end
      # We want to slim this down...
      def install_ruby_and_rubygems
        cmd=<<-EOC
          echo 'Installing ruby...'
          apt-get -y install build-essential ruby1.8-dev ruby1.8 ri1.8 rdoc1.8 irb1.8 libreadline-ruby1.8 libruby1.8
          sudo ln -s /usr/bin/ruby1.8 /usr/local/bin/ruby
          sudo ln -s /usr/bin/ri1.8 /usr/local/bin/ri
          sudo ln -s /usr/bin/rdoc1.8 /usr/local/bin/rdoc
          sudo ln -s /usr/bin/irb1.8 /usr/local/bin/irb
          echo '-- Installing Rubygems'
          cd /usr/local/src
          wget http://rubyforge.org/frs/download.php/35283/rubygems-1.1.1.tgz
          tar -xzf rubygems-1.1.1.tgz
          cd rubygems-1.1.1
          sudo ruby setup.rb
          sudo ln -s /usr/bin/gem1.8 /usr/bin/gem
          sudo gem update --system
          sudo gem install aws-s3 amazon-ec2 aska rake yaml poolparty --no-rdoc --no-ri --no-test -y
        EOC
        ssh(cmd.runnable)
      end
    end
    
  end
end