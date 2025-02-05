class ProvisionHandler
  attr_reader :order

  def initialize(order)
    @order = order
  end

  def refresh!
    if refreshable?
      ensure!
    else
      delete!
    end
  end

  def ensure!
    referrer_provision.provision = current_provision
    referrer_provision.save
  end

  def delete!
    referrer_provision.delete
  end

  def refreshable?
    valid_order? && valid_provision?
  end

  # the order is binded to a referrer, was purchased and
  # is not part of any custom pricing ; like reseller
  def valid_order?
    order.referrer && order.bought? && !order.from_reseller?
  end

  def valid_provision?
    current_provision > 0.0
  end

  private

    def referrer_provision
      @referrer_provision ||= ReferrerProvision.where(order: order, referrer: order.referrer).first || ReferrerProvision.create(order: order, referrer: order.referrer)
    end

    # live referrer provision before it's saved in the database
    def current_provision
      order.order_items.reduce(0) do |acc, order_item|
        if order_item.referrer_rate > 0.0
          calculation_price = (order_item.total_price_with_taxes * ((100 - order.coupon_discount_in_percent) / 100)) - order_item.total_taxes
          acc += calculation_price * order_item.referrer_rate / 100 # goods price
        else
          acc += 0.0
        end
      end
    end
end
