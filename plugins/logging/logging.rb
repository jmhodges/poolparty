=begin rdoc
  Sample logging plugin
  
  We declare this is a plugin by subclassing the PoolParty::Plugin class
=end
require "logger"
class Logging < PoolParty::Plugin
  # For this plugin, we want to monitor when instances start up, when the shutdown and the load
  # plus, I also want to store the status of the cloud at any given point.
  after_start :log_start
  after_become_master :log_change_master
  after_add_instance :log_new_instance
  after_terminate_instance :log_stop_instance
  after_check_stats :log_new_stats
  
  def log_start(caller)
    log  "#{Time.now},[START]"
  end  
  # Variables in the RemoteInstance class are now available to us
  # in this lower class
  def log_change_master(caller)
    log  "#{caller.ip},#{caller.name},[NEW MASTER]"
  end  
  # Variables in the Master class are now available to us
  # in this plugin
  def log_new_instance(caller)
    log  "#{caller.ip},#{Time.now},[ADDING NEW INSTANCE]"
  end
  def log_stop_instance(caller)
    log  "#{caller.ip},#{Time.now},[TERMINATING INSTANCE]"
  end
  def log_new_stats(caller)
    log  "#{caller.web},#{caller.cpu},[STATS]"
  end
  def log(str="")
    logger << "#{str}\n"
  end
  def logger
    @logger ||= Logger.new("logs/#{Application.environment.to_s}")
  end
end