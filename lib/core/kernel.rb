=begin rdoc
  Kernel overloads
=end
module Kernel
  # Nice wait instead of sleep
  def wait(time=10)
    sleep time.is_a?(String) ? eval(time) : time
  end
end