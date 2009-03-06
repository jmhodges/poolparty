# Class: PuppetResolver< DependencyResolver
#
#
module PoolParty
  
  class PuppetResolver< DependencyResolver
    
    permitted_resource_options({
      :file => [:content, :mode, :user]
    })
    
    def compile(props=@properties_hash, tabs=0)
      [ 
        options_to_string(props[:options],tabs),
        resources_to_string(props[:resources],tabs),
        services_to_string(props[:services],tabs)
      ].join("\n")
    end
    
    def options_to_string(opts,tabs=0)
      opts.map {|k,v| "#{tf(tabs)}$#{k} = #{to_option_string(v)}"}.join("\n") if opts
    end
    
    def resources_to_string(opts,tabs=0)
      if opts
        opts.map do |type, arr|          
          arr.map do |res|
            permitted_resource_res = res.reject {|k,v| !permitted_option?(type, k) }
            "#{tf(tabs)}#{type} { \"#{res.has_key?(:name) ? res.delete(:name) : "Error" }\": #{res.empty? ? "" : "\n#{tf(tabs+1)}#{hash_flush_out(permitted_resource_res).join("\n#{tf(tabs+1)}")}"}\n#{tf(tabs)}}"
          end
        end
      end
    end
    
    def permitted_option?(ty, key)
      if permitted_resource_options.has_key?(ty)
        permitted_resource_options[ty].include?(key) || key == :name
      else
        true
      end
    end
    
    def services_to_string(opts,tabs=0)
      if opts
        opts.map do |klassname, klasshash|
          "\n#{tf(tabs)}class #{klassname.to_s.gsub(/pool_party_/, '').gsub(/_class/, '')} {#{tf(tabs)}#{compile(klasshash,tabs+1)}#{tf(tabs)}}"
        end
      end
    end
    
    def tf(count)
      "\t" * count
    end
    
    def hash_flush_out(hash, pre="", post="")
      hash.map {|k,v| "#{pre}#{k} => #{to_option_string(v)}#{post}"}
    end
    
    def to_option_string(obj)
      case obj
      when String
        "\"#{obj}\""
      when Array
        "[ #{obj.map {|e| to_option_string(e) }.reject {|a| a.nil? || a.empty? }.join(", ")} ]"
      else
        "#{obj}"
      end
    end
    
    # This is the method we use to turn the options into a string to build the main 
    # puppet manifests
    def option_type(ns=[])
      a_template = (self =~ /template/) == 0
      a_service = self =~ /^[A-Z][a-zA-Z]*\[[a-zA-Z0-9\-\.\"\'_\$\{\}\/]*\]/
      a_function = self =~/(.)*\((.)*\)(.)*/
      if is_a?(PoolParty::Resources::Resource)
        self.to_s
      else
        (a_service || a_template || a_function) ? self : "'#{self}'"
      end    
    end
    
  end

end