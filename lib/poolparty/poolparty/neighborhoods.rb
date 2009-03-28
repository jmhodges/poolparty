require "#{::File.dirname(__FILE__)}/../schema"

module PoolParty
  class Neighborhoods
    attr_reader :schema
    
    def initialize(json)
      if json.is_a?(Array)
        json = {:instances => json.map {|entry| disect(entry) }}
      end
      raise Exception.new("You must pass a string or a hash to Neighborhoods") unless json
      @schema = PoolParty::Schema.new(json)
      raise Exception.new("No instances found in the Neighborhoods schema") unless @schema.instances
    end
    
    def instances
      @instances ||= @schema.instances.map {|line| disect(line) }
    end
    
    def [](at)
      instances[at] if at >= 0 && at < instances.size
    end
    
    def disect(line)
      case line
      when String
        arr = line.split("\t")
        {:name => arr[0], :ip => arr[1]}
      else
        line
      end
    end
    
    def each(&block)
      instances.each &block
    end
    
    # TODO: Make this into something useful
    def clump(filepath=nil)
      out = instances.to_json
      ::File.open(filepath, "w") {|f| f << out } if filepath
      out
    end
    
    def self.clump(json, filepath=nil)
      new(json).clump(filepath)
    end
    
    def self.load_default
      def_file = [
        Dir.pwd,
        Default.base_config_directory,
        Default.remote_storage_path,
        Default.tmp_path,
        Default.poolparty_home_path
      ].select do |dir|
        filepath = ::File.expand_path("#{dir}/neighborhood.json")
        filepath if ::File.file?(filepath)
      end.first || nil
      def_file ? new( open(::File.expand_path("#{def_file}/neighborhood.json")).read ) : raise
    end
    
  end
end