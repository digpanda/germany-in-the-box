class Notifier
  class Customer < Notifier
    attr_reader :user, :unique_id

    def initialize(user, unique_id: nil)
      @user = user
      @unique_id = unique_id
    end

    def welcome
      dispatch(
        title: '注册成功，欢迎光临来因盒！',
        desc: '亲，欢迎你到来因盒购物。'
      ).perform
    end

    def test
      dispatch(
        title: 'this is a test',
        desc: 'this was supposed to be sent on wechat'
      ).perform(:wechat)
    end

    def order_was_paid(order)
      dispatch(
        title: "来因盒通知：付款成功，已通知商家准备发货 （订单号：#{order.id})",
        desc: "你好，你的订单#{order.id}已成功付款，已通知商家准备发货。若有疑问，欢迎随时联系来因盒客服：user@germanyinthebox.com"
      ).perform
    end

    def reward_was_given(reward)
      dispatch(
        title: "您的邮箱验证奖励",
        desc: "#{reward.read}",
      ).perform(:wechat, :email)
    end

    def order_is_being_processed(order)
      dispatch(
        title: '你的订单已出货',
        desc: '你的订单已被商家寄出'
      ).perform
    end

    def referrer_provision_was_raised(order_payment, referrer, referrer_provision)
      dispatch(
        title: '一位客户',
        desc: "顾客#{order_payment.order.shipping_address.decorate.full_name}在您的推荐下在来因盒平台下了一个#{order_payment.order.total_price.in_euro.display}的订单。您现在的总奖金为#{referrer.current_balance.in_euro.display} (订单奖金 +#{referrer_provision.provision.in_euro.display})"
      ).perform(:sms)
    end

    def order_has_been_shipped(order)
      # if it's a reseller order then we send the SMS to the reseller himself
      # else we just send it out to the shipping address
      if order.from_reseller?
        mobile_recipient = order.user.mobile
      else
        mobile_recipient = order.shipping_address.mobile
      end

      dispatch(
        mobile: "#{mobile_recipient}",
        title: '发货通知',
        desc: "亲爱的顾客，您的订单#{order.id}已安排发货。快递单号为：#{order.order_tracking&.delivery_id}，您可以访问快递100网站查询快递状态 http://www.kuaidi100.com"
      ).perform(:sms)
    end

    def published_link(link)
      dispatch(
        title: I18n.t('referrer.a_new_link_was_published'),
        scope: :referrer_links,
        metadata: { link_id: link.id },
        unique_id: "#{link.id}"
      ).perform(:db) # only database
    end
  end
end
