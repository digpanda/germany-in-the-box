module SmartExchange
  module Utils
    module Options

      def valid_until(block)
        @@valid_until = block
      end

      def exec_valid_until
        @@valid_until.call
      end

      def after_match(action)
        @@after_match = action
      end

      def exec_after_match
        @@after_match
      end

    end
  end
end
