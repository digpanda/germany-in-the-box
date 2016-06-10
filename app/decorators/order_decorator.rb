class OrderDecorator < Draper::Decorator

  delegate_all
  decorates :order

  def total_price_in_currency
    object.total_price * Settings.instance.exchange_rate_to_yuan
  end

  def total_price_with_currency
    "%.2f#{Settings.instance.platform_currency.symbol}" % total_price_in_currency
  end

  def is_success?
    self.status == :success
  end

end