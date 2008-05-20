module PoolParty
  class Ubuntu
    
    def self.define_tasks!
      namespace(:ubuntu) do
        
        namespace(:haproxy) do
          desc <<-DESC
          Installs HAproxy
          DESC
          task :install => [:go_working] do
            @cmd ||= []
            haproxy_url = "http://haproxy.1wt.eu/download/1.3/src/haproxy-1.3.15.tar.gz"
            cmd =<<-EOC
              wget #{haproxy_url}
              tar -zxf haproxy-1.3.15.tar.gz
              cd haproxy-1.3.15
              configure
              make
              sudo make install
            EOC
            @cmd << cmd.gsub(/\n/, " && ")
            exec_cmd
          end
        end        
        
      end
      
    end
    
  end
end

PoolParty::Ubuntu.define_tasks!