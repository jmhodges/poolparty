=begin rdoc
  Basic monitor on the cpu stats
=end
module Web
  module Master
    # Get the average web request capabilities over the cloud
    def web
      nodes.size > 0 ? nodes.inject(0) {|i,a| i += a.web } / nodes.size : 0.0
    end
  end

  module Remote
    def web
      str = ssh("httperf --server localhost --port #{Application.client_port} --num-conn 3 --timeout 5 | grep 'Request rate'")
      str[/[.]* ([\d]*\.[\d]*) [.]*/, 0].chomp.to_f
    rescue
      0.0
    end    
  end
  
end

PoolParty.register_monitor Web