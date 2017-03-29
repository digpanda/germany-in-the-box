# prepare an order to be transmitted to the Alipay server
class CheckoutGateway
  class WechatpayGate < Base

    include Rails.application.routes.url_helpers

    attr_reader :base_url, :user, :order, :payment_gateway, :identity_solver

    def initialize(base_url, user, order, payment_gateway, identity_solver)
      @base_url = base_url
      @user  = user
      @order = order
      @payment_gateway = payment_gateway
      @identity_solver = identity_solver
    end

    # we access the Wirecard::Hpp library and generate the needed datas
    # make a new OrderPayment linked to the request which we will manipulate later on
    def checkout!
      prepare_order_payment!
      SlackDispatcher.new.message(process!) # TO UNDERSTAND THE PROBLEM
      process!
    end

    private

    # {"xml"=>
    #     {"return_code"=>"SUCCESS",
    #      "return_msg"=>"OK",
    #      "appid"=>"wxfde44fe60674ba13",
    #      "mch_id"=>"1354063202",
    #      "nonce_str"=>"cvTr8zN4EU4RTvFt",
    #      "sign"=>"5F7FB422CC25A8B8287EA8AF99E8D192",
    #      "result_code"=>"SUCCESS",
    #      "prepay_id"=>"wx201703161727381d0112c4620476236953",
    #      "trade_type"=>"JSAPI"}},
    #  "return_code"=>"SUCCESS",
    #  "return_msg"=>"OK",
    #  "appid"=>"wxfde44fe60674ba13",
    #  "mch_id"=>"1354063202",
    #  "nonce_str"=>"cvTr8zN4EU4RTvFt",
    #  "sign"=>"5F7FB422CC25A8B8287EA8AF99E8D192",
    #  "result_code"=>"SUCCESS",
    #  "prepay_id"=>"wx201703161727381d0112c4620476236953",
    #  "trade_type"=>"JSAPI"}
    #
    #  result_code"=>"FAIL"

    def unified_order
      @unified_order ||= WxPay::Service.invoke_unifiedorder({
        body: "Order #{order.id}-#{order_payment.id}",
        out_trade_no: "#{order_payment.id}",
        total_fee: total_fee,
        spbill_create_ip: '127.0.0.1',
        notify_url: "#{base_url}#{api_webhook_wechatpay_customer_path}",
        trade_type: 'JSAPI', # 'JSAPI', # could be "JSAPI", "NATIVE" or "APP",
        openid: openid
      })
    end

    def javascript_pay_request
      @javascript_pay_request ||= WxPay::Service.generate_js_pay_req({
        prepayid: unified_order["prepay_id"],
        noncestr: unified_order["nonce_str"]
      })
    end

    # this is supposedly inherited
    # but we don't want to risk wechatpay to fail anytime
    def order_payment
      @order_payment ||= OrderPayment.new
    end

    def process!
      {
        unified_order: unified_order,
        javascript_pay_request: javascript_pay_request
      }
    end

    def total_fee
      (order.end_price.in_euro.to_yuan.amount * 100).to_i
    end

    def openid
      if Rails.env.production?
        SlackDispatcher.new.message("OPENID IS : #{user.wechat_openid}")
        user.wechat_openid
      else
        user.wechat_openid
        # 'oKhjVvoKBlhnV5lBTQQdSI7sd0Tg' # Laurent's openid which was authorized in Wechatpay Dashboard
        # 'oKhjVvrPwElKx3EG4QmeGDl2-KFo' # Sha's openid
      end
    end

  end
end
