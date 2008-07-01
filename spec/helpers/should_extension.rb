module Spec
  module Mocks
    module Methods
      def should_receive_callback(sym, opts={}, &block)
        begin
          __mock_proxy.add_message_expectation(opts[:expected_from] || caller(1)[0], sym.to_sym, opts, &block)
        rescue Exception => e
        end        
      end
    end
  end
end