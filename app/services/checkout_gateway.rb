class CheckoutGateway < BaseService

  ACCEPTABLE_PROVIDERS = [:wirecard, :alipay, :wechatpay]

  include Rails.application.routes.url_helpers
  attr_reader :request, :user, :order, :payment_gateway, :identity_solver

  def initialize(request, user, order, payment_gateway, identity_solver)
    @request = request
    @user = user
    @order = order
    @payment_gateway = payment_gateway
    @identity_solver = identity_solver
  end

  def perform
    return return_with(:error, "Provider not accepted.") unless acceptable_provider?
    return self.send(payment_gateway.provider)
  end

  def wirecard
    return_with(:success, :page => wirecard_checkout)
  rescue Wirecard::Base::Error => exception
    return_with(:error, "An error occurred while processing the gateway (#{exception})")
  end

  def alipay
    return_with(:success, :url => alipay_checkout_url)
  end

  def wechatpay
    # Temporary solution to see if it pays
    return_with(:success, :url => wechatpay_checkout)
  end

  private

  def acceptable_provider?
    ACCEPTABLE_PROVIDERS.include? payment_gateway.provider
  end

  def wechatpay_checkout
    @wechatpay_checkout_url ||= begin
      WechatpayCheckout.new(base_url, user, order, payment_gateway, identity_solver).checkout!
      root_url
    end
  end

  def alipay_checkout_url
    @alipay_checkout_url ||= AlipayCheckout.new(base_url, user, order, payment_gateway, identity_solver).checkout_url!
  end

  # NOTE : this will create a new payment entry and prepare it
  def wirecard_checkout
    @wirecard_checkout ||= WirecardCheckout.new(base_url, user, order, payment_gateway.payment_method).checkout!
  end

  def base_url
    "#{request.protocol}#{request.host_with_port}/"
  end

end
