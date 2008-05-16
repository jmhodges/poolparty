module Kernel
  def wait(time=10)
    sleep time.is_a?(String) ? eval(time) : time
  end
end