module PoolParty
  module Os
    
    class Bootstrap
      def initialize(ri)
        @ri = ri
      end
      def setup
        cmd=<<-EOC
          mkdir /usr/local/working
          cd /usr/local/working
        EOC
        exec_remote(@ri, {:cmd => cmd})
      end
      def install_ruby
        
      end
      # HAproxy
      def install_haproxy
        cmd=<<-EOC
          cd /usr/local/src
          wget http://haproxy.1wt.eu/download/1.3/src/haproxy-1.3.12.1.tar.gz
          cd haproxy-1.3.12.1
          make
          mv haproxy /usr/local/bin/
        EOC
        exec_remote(@ri,{:cmd => cmd})
      end
      # FIX ME
      def configure_haproxy(nodes=[])
        cmd=<<-EOC
        mkdir /etc/haproxy
        echo "#{open(self.class.haproxy_config_file) {|w| w.read}}" > /etc/haproxy/haproxy.conf
        echo "
        listen web_proxy 127.0.0.1::client_port
          server web1 127.0.0.1:#{Application.client_port + 10} weight 1 minconn 3 maxconn 6 check inter 30000
          #{nodes.collect {|node| node.haproxy}.join("\n")}
        } >> /etc/haproxy/haproxy.conf
        EOC
        cmd ^ {:client_port => Application.client_port}
        exec_remote(@ri, {:cmd => cmd})
      end
      def install_monit
        cmd=<<-EOM
          wget http://www.tildeslash.com/monit/dist/monit-4.9.tar.gz
          tar zxvf monit-4.9.tar.gz
          cd monit-4.9
          ./configure
          make && make install
        EOM
        exec_remote(@ri, {:cmd => cmd})
      end
      def write_hosts_file(nodes=[])
        cmd=<<-EOM
          cd /etc
          cat #{@hosts.collect {|h| h.host_entry }.join("\n")} >> hosts
        EOM
        exec_remote(@ri, {:cmd => cmd})
      end
      
      class << self
        # change me
        def haproxy_config_file
          File.join(Application.root_dir, "..", "config", "haproxy.conf")
        end
      end
    end
    
  end
end