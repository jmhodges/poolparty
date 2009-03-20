module PoolParty    
  class GitResource
    
    virtual_resource(:git) do
      def loaded(*args)
        has_package(:name => "git-core")
      end
    end
    
    virtual_resource(:git_repos) do
      
      def loaded(opts={}, &block)
        has_package("git-core")
        has_git_repository
      end
            
      def has_git_repository
        has_exec({:name => key, :requires => [get_directory("#{working_dir}"), get_package("git-core")] }) do
          command requires_user ? "git clone #{requires_user}@#{source} #{working_dir}" : "cd #{working_dir} && git clone #{source}"
          cwd "#{working_dir if working_dir}"
          creates creates_dir
        end                
        has_exec(:name => "update-#{name}", :cwd => ::File.dirname( creates_dir )) do          
          command "git pull"
        end                
      end
      
      def at(dir)
        working_dir dir
        has_directory(::File.dirname(dir))
        has_directory(:name => "#{dir}", :requires => get_directory("#{::File.dirname(dir)}"))
      end
      
      def to(dir)
        at(dir)
      end
      
      def creates_dir
        "#{::File.join( working_dir, ::File.basename(source, ::File.extname(source)) )}/.git"
      end
      
      # Since git is not a native type, we have to say which core resource
      # it is using to be able to require it
      def class_type_name
        "exec"
      end
      
    end
    
  end
end