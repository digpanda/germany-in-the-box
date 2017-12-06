# when someone triggers the menu on wechat service
# it will go down here to send a callback
module WechatBot
  class Event < Base
    class Click < Base
      attr_reader :user, :event_key

      def initialize(user, event_key)
        @user = user
        @event_key = event_key.downcase # we downcase the event for clicks only
      end

      # menu click handling here
      def handle
        SlackDispatcher.new.message("EVENT KYE IS #{event_key}")
        case event_key
        when 'specialdeal'
          SlackDispatcher.new.message("SPECIAL DEAL FROM CLICK WAS TRIGGERED")
          # it simulate an exchange with the special deal keyword
          SmartExchange::Process.new(user, 'special deal').perform
          SlackDispatcher.new.message("IT WAS PERFORMED")
        when 'offers'
          # it simulate an exchange with the offers keyword
          SmartExchange::Process.new(user, '奖励').perform
        when 'groupchat'
          messenger.image! path: '/images/wechat/group.jpg'
        when 'chatsale'
          messenger.text! data(:chatsale)
          messenger.image! path: '/images/wechat/wechat_support_qr.jpg'
        when 'support'
          # it simulate an exchange with the support keyword
          SmartExchange::Process.new(user, '客服').perform
        when 'ping'
          messenger.text! data(:ping)
        end

        return_with(:success)
      end

    end
  end
end
