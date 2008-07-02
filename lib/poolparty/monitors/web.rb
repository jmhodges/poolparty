=begin rdoc
  Basic monitor on the cpu stats
=end
require "poolparty"

module Web
  module Master
    # Get the average web request capabilities over the cloud
    def web
      nodes.size > 0 ? nodes.inject(0) {|i,a| i += a.web } / nodes.size : 0.0
    end
  end

  module Remote
    def web
      out = begin
        str = run("httperf --server localhost --port #{Application.client_port} --num-conn 3 --timeout 5 | grep 'Request rate'")
        str[/[.]* ([\d]*\.[\d]*) [.]*/, 0].chomp.to_f
      rescue Exception => e
        0.0
      end
      PoolParty.message "Web requests: #{out}"
      out
    end
  end
  
end

PoolParty.register_monitor Web