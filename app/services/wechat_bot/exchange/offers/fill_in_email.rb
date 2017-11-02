class WechatBot
  class Exchange < WechatBot::Base
    class Offers < Exchange::Base
      class FillInEmail < Exchange::Base

        VALID_UNTIL = 1.hours.from_now.freeze

        def request
          '1'
        end

        def response
          SlackDispatcher.new.message("FILL IN EMAIL ASKED")
          messenger.text! 'Please enter your email'
        end
      end
    end
  end
end
