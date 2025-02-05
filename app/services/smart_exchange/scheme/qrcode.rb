module SmartExchange
  module Scheme
    class Qrcode < Base

      # valid_until -> { 7.days.from_now }

      def request
        if user&.referrer
          '二维码'
        else
          false
        end
      end

      def response
        messenger.image! url: "#{guest_referrer_qrcode_url(user.referrer)}.jpg"
      end
    end
  end
end
