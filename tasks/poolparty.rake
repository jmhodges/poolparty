desc "Run the specs"
task :slow_spec do
  Dir["#{::File.dirname(__FILE__)}/../spec/poolparty/**/*_spec.rb"].each do |sp|
    puts `spec #{sp}`
  end
end
namespace(:poolparty) do
  namespace(:setup) do
    desc "Generate a manifest for quicker loading times"
    task :manifest do
      $GENERATING_MANIFEST = true
      out = capture_stdout do
        $_poolparty_load_directories.each do |dir|
          PoolParty.require_directory ::File.join(::File.dirname(__FILE__), '../lib/poolparty', dir)
        end
      end
      ::File.open(::File.join(::File.dirname(__FILE__), '../config', "manifest.pp"), "w+") {|f| f << out.map {|f| "#{f}"} }
      puts "Manifest created"
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