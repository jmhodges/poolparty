class Exception
  def nice_message(padding="")
    "#{padding}#{message}\n#{padding}" + backtrace.join("\n#{padding}")
  end
end