module PoolParty    
  module Resources
        
    class File < Resource      
      
      default_options({
        :ensure => "file",
        :mode => 644
        # :owner => "#{Base.user}"
      })
      
      def disallowed_options
        [:name, :template, :cwd]
      end
      
      def after_create
        if options.include?(:template)
          filename = self.template
          file = ::File.basename(filename)
          raise TemplateNotFound.new("no template given") unless file

          template_opts = (parent ? options.merge(parent.options) : options)
          options.merge!(:content => Template.compile_file(filename, template_opts))
        end
      end
      
    end
    
  end
end