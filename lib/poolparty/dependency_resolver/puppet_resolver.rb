# Class: PuppetResolver< DependencyResolver
#
#
module PoolParty
  
  class PuppetResolver< DependencyResolver
    
    def compile
      [options_to_string].join("\n")
    end
    
    def options_to_string      
      @properties_hash[:options].map {|k,v| "$#{k} = #{to_option_string(v)}"}.join("\n") if @properties_hash[:options]
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