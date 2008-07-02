# require "vlad"
# class Rake::RemoteTask < Rake::Task  
#   def run command
#     cmd = [ssh_cmd, ssh_flags, target_host].compact
#     result = []
#     
#     commander = cmd.join(" ") << " \"#{command}\""
#     warn commander if $TRACE
# 
#     pid, inn, out, err = popen4(commander)
# 
#     inn.sync   = true
#     streams    = [out, err]
#     out_stream = {
#       out => $stdout,
#       err => $stderr,
#     }
# 
#     # Handle process termination ourselves
#     status = nil
#     Thread.start do
#       status = Process.waitpid2(pid).last
#     end
# 
#     until streams.empty? do
#       # don't busy loop
#       selected, = select streams, nil, nil, 0.1
# 
#       next if selected.nil? or selected.empty?
# 
#       selected.each do |stream|
#         if stream.eof? then
#           streams.delete stream if status # we've quit, so no more writing
#           next
#         end
# 
#         data = stream.readpartial(1024)
#         out_stream[stream].write data
# 
#         if stream == err and data =~ /^Password:/ then
#           inn.puts sudo_password
#           data << "\n"
#           $stderr.write "\n"
#         end
# 
#         result << data
#       end
#     end
# 
#     PoolParty.message "execution failed with status #{status.exitstatus}: #{cmd.join ' '}" unless status.success?
# 
#     result.join
#   end
#   
#   def rsync local, remote
#     cmd = [rsync_cmd, rsync_flags, local, "#{@target_host}:#{remote}"].flatten.compact
#   
#     success = system(*cmd.join(" "))
# 
#     unless success then
#       raise Vlad::CommandFailedError, "execution failed: #{cmd.join ' '}"
#     end
#   end
#   def set name, val = nil, &b
#     rt.set name, val, &b
#   end
#   def rt
#     @rt ||= Rake::RemoteTask
#   end
#   
#   def target_hosts
#     if hosts = ENV["HOSTS"] then
#       hosts.strip.gsub(/\s+/, '').split(",")
#     elsif options[:single]
#       @roles = {}; @roles[:app] = {}      
#       @roles[:app][options[:single]] = options[:single]
#       roles = Rake::RemoteTask.hosts_for(@roles)
#     else
#       roles = options[:roles]
#       roles ? Rake::RemoteTask.hosts_for(roles) : Rake::RemoteTask.all_hosts
#     end
#   end
# end