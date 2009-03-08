# STUB FOR NOW
# TODO
module PoolParty
  class Key
    
    attr_accessor :filepath
    
    def initialize(filepath=nil)
      @filepath = filepath ? filepath : "id_rsa"
    end
    
    def exists?
      full_filepath != nil
    end
    
    def content
      @content ||= exists? ? open(full_filepath).read : nil
    end
        
    def full_filepath
      @full_filepath ||= ::File.file?(::File.expand_path(filepath)) ? ::File.expand_path(filepath) : search_in_known_locations
    end
    
    def search_in_known_locations
      self.class.keypair_paths.each do |path|
        full_path = ::File.join( ::File.expand_path(path), filepath)
        return full_path if ::File.exists?(full_path)
      end
      nil
    end
    
    def self.keypair_paths
      [
        "#{ENV["HOME"]}/.ssh",
        "#{Base.poolparty_home_path}/keys",
        Base.base_keypair_path,
        Base.base_config_directory,
        Base.remote_storage_path,
        Dir.pwd
      ]
    end
    
  end
end