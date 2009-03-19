require "parenting"
module PoolParty
  
  class Script
    include Parenting
    
    def self.inflate_file(file)
      inflate open(file).read if file
    end
        
    def self.inflate(script, file="__SCRIPT__")
      module_eval script, file
      # a = new
      # a.instance_eval <<-EOM
      #   def run_child(pa)
      #     context_stack.push pa
      #     #{str}
      #     context_stack.pop
      #     remove_method(:run_child)
      #     self
      #   end
      # EOM
      # a.run_child(self)
      # a
    end
        
    def self.to_ruby(opts={},&blk)
      blk.to_ruby(opts)
    end
    
    def self.for_save_string
      returning Array.new do |out|
        pools.collect {|n,pl| pl}.each do |pl|
          out << "pool :#{pl.name} do"
          clouds.each do |n,cl|
            out << <<-EOE
  cloud :#{cl.name} do
    #{cl.minimum_runnable_options.map {|o| "#{o} #{cl.send(o).respec_string}"}.join("\n")}
  end
            EOE
          end
          out << "end"
        end
      end.join("\n")
    end
    
    def self.save!(to_file=true)
      write_to_file_in_storage_directory(Base.default_specfile_name, for_save_string) if to_file
      for_save_string
    end
    
  end
  
end