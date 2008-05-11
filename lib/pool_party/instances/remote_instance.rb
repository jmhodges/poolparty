module PoolParty
  class RemoteInstance
    attr_reader :load, :ip
    
    def initialize(obj)
      @ip = obj[:ip]
    end
            
    # Process the actual proxy request against the server
    def process(env, rackreq)
      headers = Rack::Utils::HeaderHash.new
      env.each { |key, value|
       if key =~ /HTTP_(.*)/
         headers[$1] = value
       end
      }      

      res = Net::HTTP.start(@ip, Application.client_port) { |http|
       m = rackreq.request_method
       req = Net::HTTP.const_get(m.capitalize).new(rackreq.fullpath, headers)
       
       case m
       when "GET", "HEAD", "DELETE", "OPTIONS", "TRACE"         
       when "PUT", "POST"
        req.body_stream = rackreq.body
        correct_body_stream(req)
       else
         raise "method not supported: #{method}"
       end
       
       http.request(req)
      }
      [res.code, Rack::Utils::HeaderHash.new(res.to_hash), [res.body]]     
    end
    
    # We have to correct the body if it is a body-stream or
    # if the length is not included in the request response
    # also, we set the content-type in the response to satisfy Rack
    def correct_body_stream(req)      
      if req.body
        req['content-length'] ||= req.body.length.to_s
        req['content-type'] ||= 'application/x-www-from-urlencoded'
        body_stream = StringIO.new(req.body)
      elsif req.body_stream
        if req['content-length']
      	  body_stream = req.body_stream
      	else
      	  if req.body_stream.respond_to?(:length)
      	    req['content-length'] = req.body_stream.length.to_s
      	    body_stream = req.body_stream
      	  else
      	    body_stream = StringIO.new(req.body_stream.read)
      	    req['content-length'] = body_stream.length.to_s
      	  end
      	end
      	req['content-type'] ||= 'application/x-www-from-urlencoded'
      end
      req.body_stream = body_stream
    end
    
    # Algorithm definition for load
    def status_level
      (cpu + memory)/2 * web
    end
    def <=>(b)
      status_level <=> b.status_level
    end
    # Define polling mechanism here
    def status
      @status ||= YAML.load(open("http://#{@ip}:#{Application.client_port}/status").read)
    end
    
    %w(cpu memory web).each {|a| define_method(a.to_sym) { status["#{a}"].to_f } }
    
  end
end