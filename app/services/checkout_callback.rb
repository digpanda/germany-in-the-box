class CheckoutCallback < BaseService
  # {"sign"=>"0ba0871c3777191fda758b07189a59c3",
  #  "trade_no"=>"2017030821001003840200345741",
  #  "total_fee"=>"1262.41",
  #  "sign_type"=>"MD5",
  #  'out_trade_no'=>"58bfc16af54bcc0a0b908c44",
  #  "trade_status"=>"TRADE_FINISHED",
  #  "currency"=>"HKD",
  #  "controller"=>"customer/checkout/callback/alipay",
  #  "action"=>"show"}
  include ErrorsHelper
  include Rails.application.routes.url_helpers

  attr_reader :user, :params, :forced_status, :cart_manager

  # NOTE : the forced status isn't currently working with alipay
  def initialize(user, cart_manager, params, forced_status = nil)
    @user = user
    @cart_manager = cart_manager
    @params = params
    @forced_status = forced_status
  end

  def wechatpay!
    order_payment = OrderPayment.where(id: params['out_trade_no']).first
    unless order_payment
      return return_with(:error, 'Order not found from the AliPay callback')
    end

    # first we make sure we got the transaction id for traceability
    order_payment.transaction_id = params['transaction_id']
    order_payment.save

    unless wechatpay_success?
      order_payment.status = :failed
      order_payment.save
      order_payment.order.refresh_status_from(order_payment)
      slack.message "[Error] checkout callback `#{I18n.t('payment.failed')}`"
      return return_with(:error, I18n.t('payment.failed'))
    end

    order_payment.status = :success
    order_payment.save
    order_payment.order.refresh_status_from(order_payment)

    manage_stocks!(order_payment.order)
    dispatch_notifications!(order_payment)
    make_first_order_challenge_completion

    return_with(:success, order_payment: order_payment)
  end

  def alipay!(mode: :unsafe)
    order = Order.where(id: params['out_trade_no']).first
    unless order
      return return_with(:error, 'Order not found from the AliPay callback')
    end

    transaction_id = params[:trade_no]
    # paid_end_price = params[:total_fee]
    # status = params[:trade_status]

    # we refresh the bare minimum and wait the notification to verify the transaction itself
    order_payment = (OrderPayment.where(transaction_id: transaction_id).first || order.order_payments.where(status: :scheduled).first)
    order_payment.transaction_id = transaction_id

    unless alipay_success?(mode)
      order_payment.status = :failed
      order_payment.save
      order_payment.order.refresh_status_from(order_payment)
      slack.message "[Error] checkout callback #{I18n.t('payment.failed')}", url: admin_order_payment_url(order_payment)
      return return_with(:error, I18n.t('payment.failed'))
    end

    if mode == :unsafe

      # we come from a normal callback so we are not sure
      # about the validity of those data
      order_payment.status = :unverified
      order_payment.save
      order_payment.order.refresh_status_from(order_payment)

    elsif mode == :safe

      # The status is success and the communication is safe
      order_payment.status = :success
      order_payment.save
      order_payment.order.refresh_status_from(order_payment)

      manage_stocks!(order_payment.order)
      dispatch_notifications!(order_payment)

    else
      return return_with(:error, 'Mode for Alipay callback unknown')
    end

    return return_with(:success, order_payment: order_payment)
  end

  def dispatch_guide_message!(order_payment)
    order = order_payment.order
    order.reload # thanks mongo !
    referrer = order.referrer
    referrer_provision = order.referrer_provision

    if referrer&.user&.mobile && referrer_provision
      # PROVISION-#{referrer_provision.id}
      Notifier::Customer.new(referrer.user, unique_id: "WECHAT-WEBHOOK-PROVISION-#{referrer_provision.id}-OUT-TRADE-NO-#{params['out_trade_no']}").referrer_provision_was_raised(order_payment, referrer, referrer_provision)
    end
  end

  def dispatch_confirm_paid_order!(order)
    Notifier::Customer.new(order.user).order_was_paid(order)
    Notifier::Shopkeeper.new(order.shop.shopkeeper).order_was_paid(order)
    EventDispatcher.new.order_was_paid(order).dispatch!
  end

  def manage_stocks!(order)
    StockManager.new(order).in_order!
    order.cart = nil
    order.save
    # cart_manager.empty!
    order.coupon&.update(last_used_at: Time.now)
  end

  private

    def wechatpay_success?
      params['return_code'] == 'SUCCESS'
    end

    def alipay_success?(mode)
      ['TRADE_FINISHED', 'TRADE_SUCCESS'].include? params[:trade_status]
    end

    def dispatch_notifications!(order_payment)
      if order_payment.status == :success
        if order_payment.order.bought?
          dispatch_guide_message!(order_payment)
          dispatch_confirm_paid_order!(order_payment.order)
          slack.paid_transaction(order_payment)
        end
      else
        slack.failed_transaction(order_payment)
      end
    end

    # make first order challenge reward
    # we have to check the reward to give for this user and all his friends
    # if the challenge was eventually started beforehand
    def make_first_order_challenge_completion
      if user
        try_to_give_reward(user)
        user.introduced.from_wechat.each do |user|
          try_to_give_reward(user)
        end
      end
    end

    def try_to_give_reward(target_user)
      reward_manager = RewardManager.new(target_user, task: :make_first_order)
      if reward_manager.started?
        reward_manager.end
      end
    end

    def slack
      @slack ||= SlackDispatcher.new
    end
end
