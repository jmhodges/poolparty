require "sprinkle"
module Sprinkle
  module Installers
    class Source < Installer

      def custom_dir(dir)
        @custom_dir = dir
      end
      
      def base_dir
        if @custom_dir
          return @custom_dir
        elsif @source.split('/').last =~ /(.*)\.(tar\.gz|tgz|tar\.bz2|tb2)/
          return $1
        end
        raise "Unknown base path for source archive: #{@source}, please update code knowledge"
      end
    end
    
  end
end