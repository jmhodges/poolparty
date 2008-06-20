package :s3fs do
  description "S3 Fuse project"
  source "http://s3fs.googlecode.com/files/s3fs-r166-source.tar.gz"
  
  requires :s3fs_deps
end

package :s3fs_deps do
  description "S3 Fuse project dependencies"
  apt %w( libcurl4-openssl-dev libxml2-dev libfuse-dev )
end