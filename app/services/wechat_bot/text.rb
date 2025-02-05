module WechatBot
  class Text < Base
    attr_reader :user, :content

    CUSTOMER_SUPPORT_CHANNEL = '#customer_support'.freeze

    def initialize(user, content)
      @user = user
      @content = content
    end

    def dispatch
      # if the exchange is recognized and successful
      # we don't need to dispatch the rest
      unless exchange.perform
        # we dispatch it to a specific slack channel
        # dedicated to the customer support
        slack_support.service_message(user, content)
        notify_admin
        messenger.text! I18n.t('bot.exchange.default')
      end

      return_with(:success)
    end

    private

      def exchange
        @exchange ||= SmartExchange::Process.new(user, content)
      end

      def slack_support
        @slack_support ||= SlackDispatcher.new(custom_channel: CUSTOMER_SUPPORT_CHANNEL)
      end

      def notify_admin
        Notifier::Admin.new.new_wechat_message(user, content)
      end
  end
end
