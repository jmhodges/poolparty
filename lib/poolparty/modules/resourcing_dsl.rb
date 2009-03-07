module PoolParty
  module ResourcingDsl
    # Overrides for syntax
    # Allows us to send require to require a resource
    def requires(str=nil)
      # str ? options.append!(:require => str) : options[:require]
      str ? options.merge!(:require => send_if_method(str)) : options[:require]
    end
    def on_change(str=nil)
      str ? options.merge!(:notify => send_if_method(str)) : options[:notify]
    end
    def ensures(str="running")
      # if %w(absent running).map {|a| self.send a.to_sym}.include?(str)
        str == "absent" ? is_absent : is_present
      # else
        # options.append!(:ensure => str)
      # end
      # str
    end
    # Allows us to send an ensure to ensure the presence of a resource
    def is_present(*args)
      options.merge!(:ensure => present)
    end
    # Ensures that what we are sending is absent
    def is_absent(*args)
      options.merge!(:ensure => absent)
    end
    # Alias for unless
    def ifnot(str="")
      options.merge!(:unless => str)
    end
    def present
      "present"
    end
    def absent
      "absent"
    end
    def cancel(*args)
      options[:cancelled] = args.empty? ? true : args[0]
    end
    def cancelled?
      options[:cancelled] || false
    end
    def printed(*args)
      options[:printed] = true
    end
    def printed?
      options[:printed] || false
    end
    # Give us a template to work with on the resource
    # Make sure this template is moved to the tmp directory as well
    # 
    # TODO: Change this method to store the template files for later
    # copying to prevent unnecessary copying and tons of directories
    # everywhere
    # def template(filename)
    #   file = ::File.basename(filename)
    #   raise TemplateNotFound.new("no template given") unless file
    #   
    #   template_opts = (parent ? options.merge(parent.options) : options)
    #   puts (template_opts.keys + options.keys).join(" ")
    #   options.merge!(:content => Template.compile_file(filename, template_opts))
    # end
    
    def render_template
      # @templates.
    end
    
    def get_client_or_gem_template(file)      
      if client_templates_directory_exists? && client_template_exists?(file)
        vputs "using custom template #{::File.join(Dir.pwd, "templates/#{file}")}"
        ::File.join(Dir.pwd, "templates/#{file}")
      else
        vputs "using standard template: #{::File.join(::File.dirname(__FILE__), "..", "templates/#{file}")}"
        ::File.join(::File.dirname(__FILE__), "..", "templates/#{file}")
      end      
    end
    def client_templates_directory_exists?
      ::File.directory?("#{Dir.pwd}/templates")
    end
    def client_template_exists?(filename)
      file = ::File.join("#{Dir.pwd}/templates", filename)
      ::File.file?(file) && ::File.readable?(file)
    end
  end
end