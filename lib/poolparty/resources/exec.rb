module PoolParty    
  module Resources
    
    class Exec < Resource
      
      default_options({
        :path => "/usr/bin:/bin:/usr/local/bin:$PATH"
      })
      
      def present
        "running"
      end
      
      def command(*args)
        if args.empty?
          options[:command] || options[:name]
        else
          options[:command] = args
          options[:name] = options[:command] unless options[:name]
        end        
      end
      
      def key
        options[:name] || options[:command]
      end
                  
    end
    
  end
end