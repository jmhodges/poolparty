=begin rdoc
  S3 overloads
=end
module AWS
  module S3
    class S3Object
       class << self
         
        alias :original_store :store
        def store(key, data, bucket = nil, options = {})
          store_folders(key, bucket, options) if options[:use_virtual_directories]
          original_store(key, data, bucket, options)
        end
        
        def streamed_store(key, filepath, bucket = nil, options = {})
          store_folders(key, bucket, options) if options[:use_virtual_directories]
          store(key,File.open(filepath), bucket)
        end
        
        def store_directory(directory, bucket, options = {})
          Dir[File.join(directory, "*")].each do |file|
            streamed_store("#{File.basename(File.dirname(file))}/#{File.basename(file)}", file, bucket, options.update(:use_virtual_directories => true))
          end
        end
  
        def store_folders(key, bucket = nil, options = {})
          folders = key.split("/")
          folders.slice!(0)
          folders.pop
          current_folder = "/"
          folders.each {|folder|
            current_folder += folder
            store_folder(current_folder, bucket, options)
            current_folder += "/"
          }
        end
  
        def store_folder(key, bucket = nil, options = {})
          original_store(key + "_$folder$", "", bucket, options) # store the magic entry that emulates a folder
        end
      end
    end
  end
end
