class PoolParser < PPprimativesParser
  def parse *a
    super(*a).value  
  rescue Exception => e
    puts e
    failure_reason ? raise(RuntimeError, failure_reason) : raise  
  end
end