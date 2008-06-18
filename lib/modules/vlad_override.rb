require "vlad"
class Rake::RemoteTask < Rake::Task
  def run command
    cmd = [ssh_cmd, ssh_flags, target_host, command].compact
    result = []
    
    warn cmd.join(' ') if $TRACE

    pid, inn, out, err = popen4(*cmd.join(" "))

    inn.sync   = true
    streams    = [out, err]
    out_stream = {
      out => $stdout,
      err => $stderr,
    }

    # Handle process termination ourselves
    status = nil
    Thread.start do
      status = Process.waitpid2(pid).last
    end

    until streams.empty? do
      # don't busy loop
      selected, = select streams, nil, nil, 0.1

      next if selected.nil? or selected.empty?

      selected.each do |stream|
        if stream.eof? then
          streams.delete stream if status # we've quit, so no more writing
          next
        end

        data = stream.readpartial(1024)
        out_stream[stream].write data

        if stream == err and data =~ /^Password:/ then
          inn.puts sudo_password
          data << "\n"
          $stderr.write "\n"
        end

        result << data
      end
    end

    unless status.success? then
      raise(Vlad::CommandFailedError,
            "execution failed with status #{status.exitstatus}: #{cmd.join ' '}")
    end

    result.join
  end
  
  def rsync local, remote
    cmd = [rsync_cmd, rsync_flags, local, "#{@target_host}:#{remote}"].flatten.compact
  
    success = system(*cmd.join(" "))

    unless success then
      raise Vlad::CommandFailedError, "execution failed: #{cmd.join ' '}"
    end
  end
  def set name, val = nil, &b
    rt.set name, val, &b
  end
  def rt
    @rt ||= Rake::RemoteTask
  end
end