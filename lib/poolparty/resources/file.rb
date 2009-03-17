module PoolParty    
  module Resources
        
    class File < Resource      
      
      default_options({
        :mode => 644
      })
      
      def after_create
        if dsl_options.include?(:template)
          puts "dsl_options include template: #{self.template}"
          filename = self.template
          options.delete(:template)
          file = ::File.basename(filename)
          raise TemplateNotFound.new("no template given") unless file

          template_opts = (parent ? options.merge(parent.options) : options)
          options.merge!(:content => Template.compile_file(filename, template_opts).gsub("\"", "\\\""))
        end
      end
      
    end
    
  end
end