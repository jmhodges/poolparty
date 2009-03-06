module PoolParty    
  module Resources
        
    class File < Resource      
      
      dsl_accessors [:name, :content, :mode, :owner]
      
      default_options({
        :mode => 644
      })      
      
      def after_create
        if options.include?(:template)
          filename = self.template
          options.delete(:template)
          file = ::File.basename(filename)
          raise TemplateNotFound.new("no template given") unless file

          template_opts = (parent ? options.merge(parent.options) : options)
          options.merge!(:content => Template.compile_file(filename, template_opts))
        end
      end
      
    end
    
  end
end