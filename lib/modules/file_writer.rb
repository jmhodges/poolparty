module PoolParty
  module FileWriter
    def write_to_file_for(f="haproxy", node=nil, str="", &block)
      clear_base_directory
      make_base_directory
      File.open("#{base_tmp_dir}/#{node ? "#{node.name}-" : ""}#{f}", "w+") do |file|
        file << str
        file << block.call if block_given?
      end
    end
    # Write a temp file with the content str
    def write_to_temp_file(str="")        
      tempfile = Tempfile.new("#{base_tmp_dir}/pool-party-#{rand(1000)}-#{rand(1000)}")
      tempfile.print(str)
      tempfile.flush
      tempfile
    end
    def with_temp_file(str="", &block)
      Tempfile.open "#{base_tmp_dir}/pool-party-#{rand(10000)}" do |fp|
        fp.puts str
        fp.flush
        block.call(fp)
      end
    end
    
    def base_tmp_dir
      File.join(user_dir, "tmp")
    end
    def make_base_directory
      `mkdir -p #{base_tmp_dir}` unless File.directory?(base_tmp_dir)
    end
    def clear_base_directory
      `rm -rf #{base_tmp_dir}/*` if File.directory?(base_tmp_dir)
    end
  end
end