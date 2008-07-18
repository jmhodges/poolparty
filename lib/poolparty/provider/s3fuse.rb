package :s3fs do
  description "S3 Fuse project"
  source "http://s3fs.googlecode.com/files/s3fs-r166-source.tar.gz" do
    custom_dir 's3fs'
    custom_install "make"
    
    post :install, "mv s3fs /usr/bin"
  end
    
  requires :s3fs_deps
end

package :s3fs_deps do
  description "S3 Fuse project dependencies"
  apt %w( libcurl4-openssl-dev libxml2-dev libfuse-dev )
  
  requires :build_essential
end