module SmartExchange
  module Scheme
    class SpecialDeal < Base

      # valid_until -> { 7.days.from_now }

      # test system to see if the whole structure works fine
      def request
        'special deal'
      end

      def response
        if package_set
          messenger.text! "#{promotion}"
          messenger.image! url: "#{guest_package_set_promote_qrcode_url(package_set)}.jpg"
        else
          messenger.text! 'No deal found.'
        end
      end

      def package_set
        @package_set ||= Setting.instance.promoted_package_set
      end

      def promotion
        Setting.instance.promoted_package_set_text
      end
    end
  end
end
