namespace(:poolparty) do
  namespace(:setup) do
    desc "Generate a manifest for quicker loading times"
    task :manifest do
      $DEBUGGING = true
      out = capture_stdout do
        $_poolparty_load_directories.each do |dir|
          PoolParty.require_directory(dir)
        end
      end
      puts out
    end
  end
  namespace :vendor do
    desc "Initialize the submodules"
    task :setup do
      `git submodule init`
    end
    desc "Update the submodules"
    task :update do
      `git submodule update`
    end
  end
end