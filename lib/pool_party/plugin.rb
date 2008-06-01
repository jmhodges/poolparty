=begin rdoc
  Allow for plugins based in callbacks
=end
module PoolParty
  class Plugin
    
    # A plugin should be able to hook into any method and run their command
    # either before or after the plugin. The syntax to hook into these commands
    # on the plugin level should look like
    #   # plugin file
    #   run_after :install, :install_nginx
    #   run_before :configure, :restart_nginx
    %w(before after).each do |type|
      eval <<-EOE
        def self.run_#{type}(wrapper, method, &block)
          # Classes that can have callbacks on them
          %w(RemoteInstance Master).each do |klass|
            if eval(klass).instance_methods.include?(wrapper.to_s)
              str = "#{type} :"+wrapper.to_s+", :"+method.to_s+", :class => '"+name.to_s+"'"
              
              p eval(klass).class_eval(%{str})
              eval(klass).send :class_eval, %{str}
            end
          end          
        end
      EOE
    end
    
    
  end
end