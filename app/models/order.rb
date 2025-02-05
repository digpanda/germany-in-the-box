require 'will_paginate/array'

class Order
  include MongoidBase
  include HasProductSummaries
  include Mongoid::Search

  # research system
  # end_price makes issues on the tests
  search_in :id, :status, :nickname, :paid_at, :total_paid, user: :id, order_tracking: [:state, :delivery_id], shipping_address: [decorate: :full_name]

  BOUGHT_OR_CANCELLED = [:paid, :shipped, :terminated, :cancelled]
  BOUGHT_OR_UNVERIFIED = [:payment_unverified, :paid, :shipped, :terminated]

  field :status,                    type: Symbol, default: :new
  field :desc,                      type: String # NOTE : this does not seem to be used anymore within the system, and for a while
  field :special_instructions, type: String
  field :logistic_partner, type: Symbol, default: :manual
  field :order_items_count,         type: Fixnum, default: 0
  field :bill_id, type: String
  field :paid_at, type: Time
  field :cancelled_at, type: Time
  field :marketing, type: Boolean, default: false

  field :shipping_cost, type: Float, default: 0.0
  field :exchange_rate, type: Float, default: 0.0

  field :coupon_applied_at, type: Time
  field :coupon_discount, type: Float, default: 0.0

  before_save :refresh_shipping_cost

  # if the order isn't bought yet and we add order_items or change anything
  # the shipping cost will be automatically refreshed
  def refresh_shipping_cost
    unless self.bought?
      self.shipping_cost = ShippingPrice.new(self).price
    end
  end

  # the taxes cost appears systematically `recalculated`
  # but it's actually taken from hard written `order_item` taxes cost
  def taxes_cost
    @taxes_cost ||= begin
      order_items.reduce(0) do |acc, order_item|
        acc + (order_item.taxes_per_unit * order_item.quantity)
      end
    end
  end

  # the referrer logic is first binded to the user
  # the coupon referrer is still present but secondary
  # def current_referrer
  #   user&.parent_referrer || coupon&.referrer
  # end

  belongs_to :shop, inverse_of: :orders
  belongs_to :user, inverse_of: :orders
  belongs_to :cart, inverse_of: :orders
  belongs_to :coupon, inverse_of: :orders

  belongs_to :referrer, inverse_of: :orders
  field :referrer_origin, type: Symbol # [:user, :coupon]

  embeds_one :shipping_address, class_name: 'Address'
  embeds_one :billing_address, class_name: 'Address'

  has_many :order_items,            inverse_of: :order,    dependent: :restrict
  has_many :order_payments,         inverse_of: :order,    dependent: :restrict
  has_many :notes,                  inverse_of: :order,    dependent: :restrict
  has_one :referrer_provision,    inverse_of: :order,    dependent: :restrict

  has_one :order_tracking, inverse_of: :order, dependent: :delete

  scope :nonempty,    ->  {  where(:order_items_count.gt => 0) }
  scope :unpaid,      ->  { self.in(status: [:new]) }
  scope :bought,      ->  { self.in(status: [:paid, :shipped, :terminated]) }
  scope :bought_or_cancelled, -> { self.in(status: BOUGHT_OR_CANCELLED) }
  scope :bought_or_unverified,      ->  { self.in(status: BOUGHT_OR_UNVERIFIED) } # cancelled isn't included in this
  scope :ongoing, -> { self.in(status: [:paid, :shipped]) }

  scope :from_month, -> { where(:c_at => { :$gte => Time.now.beginning_of_month }) }

  def bought_or_cancelled?
    BOUGHT_OR_CANCELLED.include? status
  end

  def cancelled?
    status == :cancelled
  end

  # :new -> didn't try to pay
  # :paying -> is inside the process of payment
  # :payment_unverified -> we couldn't verify the payment (contact admin)
  # :payment_failed -> the payment failed (make another try when we got the functionality)
  # :cancelled -> the order has been canceled
  # :paid -> it was paid
  # :shipped -> the shopkepper has sent the package
  # :terminated -> the shipment has been done totally
  # NOTE : don't forget to update the tooltips too
  validates :status, presence: true , inclusion: { in: [:new, :paying, :payment_unverified, :payment_failed, :cancelled, :paid, :shipped, :terminated] }

  summarizes sku_list: :order_items, by: :quantity

  after_save :make_bill_id, :update_paid_at, :update_cancelled_at, :refresh_referrer_provision

  # refresh order status from payment
  # if the order is still not send / paid, it checks
  # if there's any change from the payment model
  def refresh_status_from(order_payment)
    unless bought_or_cancelled?
      if order_payment.status == :success
        self.status = :paid
      elsif order_payment.status == :unverified
        self.status = :payment_unverified
      elsif order_payment.status == :failed
        self.status = :payment_failed
      end
      self.save!
    end
  end

  # the price origins is taken from the items
  # this value is defined on the fly because
  # in the future we could have mixed price origins
  # the prefered strategy to make conditions over this is to exclude
  # such as `!price_origin.include? :reseller_price`
  # because the array can be empty
  def price_origins
    order_items.map(&:price_origin).uniq
  end

  def from_reseller?
    price_origins.include?(:default_reseller_price) || price_origins.include?(:junior_reseller_price) || price_origins.include?(:senior_reseller_price)
  end

  def coupon_discount_in_percent
    # we use the total_price_with_taxes because
    # the coupon_discount is calculated with taxes
    coupon_discount / total_price_with_taxes * 100
  end

  def refresh_referrer_provision
    ProvisionHandler.new(self).refresh!
  end

  # total price of the products in the order (raw price before any alteration)
  # memoization for performance
  def total_price
    order_items.inject(0) do |sum, order_item|
      # sum += order_item.quantity * order_item.price # after_discount_price
      sum += order_item.total_price # after_discount_price
    end
  end

  def total_price_with_taxes
    total_price + taxes_cost
  end

  def total_discount
    coupon_discount
  end

  def total_discount_percent
    total_price_with_discount / total_price
  end

  # extra costs (shipping and taxes)
  def extra_costs
    shipping_cost + taxes_cost
  end

  # total price with the coupon discount if any
  def total_price_with_discount
    total_price_with_taxes - coupon_discount
  end

  # total price of the products with the shipping cost
  def total_price_with_extra_costs
    total_price + extra_costs
  end

  # this the price with discount applied and adding up the extra costs afterwards
  def total_price_with_discount_and_extra_costs
    total_price_with_discount + shipping_cost # taxes are included in the discount price
  end

  # this is the end price which the customer has to pay
  # this consider everything that has to be applied such discount and extra costs
  def end_price
    total_price_with_discount_and_extra_costs
  end

  def total_paid_in_yuan
    total_paid(:cny).in_yuan.display
  end

  def total_paid_in_euro
    total_paid(:eur).in_euro.display
  end

  def total_paid(currency = :cny)
    self.order_payments.where(status: :success).all.reduce(0) do |acc, order_payment|
      amount = order_payment.send("amount_#{currency}")
      if order_payment.refund?
        acc + -(amount)
      else
        acc + amount
      end
    end
  end

  def package_sets
    order_items.where(:package_set.ne => nil).reduce([]) do |acc, order_item|
      acc << order_item.package_set
    end.uniq
  end

  def only_package_set?
    order_items.without_package_set.count == 0
  end

  def displayable_total_quantity
    package_sets_quantity + casual_products_quantity
  end

  # NOTE : should we cancel this way of calculating and use `displayable_total_quantity` as a whole ?
  def total_quantity
    order_items.inject(0) { |sum, order_item| sum += order_item.quantity }
  end

  def total_volume
    order_items.inject(0) { |sum, order_item| sum += order_item.volume }
  end

  def discount?
    coupon_applied_at.present?
  end

  def processable?
    status == :paid
  end

  def terminated?
    status == :terminated
  end

  def cancellable?
    status != :cancelled && status != :unverified && status != :terminated
  end

  def shippable?
    self.bought? && self.status != :shipped && self&.order_tracking&.delivery_id&.present?
  end

  def paid?
    ([:new, :paying].include? self.status) == false
  end

  # we considered as bought any status after paid
  def bought?
    [:paid, :shipped, :terminated].include?(status) && paid_at
  end

  def new?
    [:new].include?(status)
  end

  def destroyable?
    order_items.count == 0 && order_payments.count == 0
  end

  def remove_coupon(identity_solver)
    CouponHandler.new(identity_solver, self.coupon, self).reset_status
    self.update(coupon_id: nil)
  end

  def bypass_locked!
    self.order_items.each do |order_item|
      order_item.bypass_locked = true
    end
  end

  def is_empty?
    self.order_items.count == 0
  end

  def timeout?
    (Date.today - self.created_at.to_date).to_i > 3
  end

  def package_set_quantity(package_set)
    package_set.reload # thanks mongo i guess
    order_items.where(package_set: package_set).count / package_set.package_skus.count
  end

  def package_sets_quantity
    package = {}
    order_items.where(:package_set.ne => nil).reduce(0) do |acc, order_item|
      package_set = order_item.package_set
      if package["#{package_set.id}"]
        acc
      else
        package["#{package_set.id}"] = true
        acc += package_set_quantity(package_set)
      end
    end
  end

  def casual_products_quantity
    order_items.where(package_set: nil).reduce(0) do |acc, order_item|
      acc += order_item.quantity
    end
  end

  def package_set_price_with_taxes(package_set)
    package_set.total_price_with_taxes * package_set_quantity(package_set)
  end

  def package_set_end_price(package_set)
    package_set.end_price * package_set_quantity(package_set)
  end

  def products_name_array
    order_items.reduce([]) do |acc, order_item|
      acc << order_item.product.name
    end
  end

  private

    def update_paid_at
      if paid_at.nil? && status == :paid
        self.paid_at = Time.now.utc
        self.save
      end
    end

    def update_cancelled_at
      if cancelled_at.nil? && status == :cancelled
        self.cancelled_at = Time.now.utc
        self.save
      end
    end

    # only the orders which were at some point will be assigned a bill id
    # the unique number in it will be equal to the total of the previous bills + 1.
    # every year the system got reset
    def make_bill_id
      if bill_id.nil? && self.bought?
        start_day = paid_at.beginning_of_day
        digits = start_day.strftime('%Y%m%d')
        num = Order.and(:bill_id.ne => nil).and(:paid_at => { :$gte => start_day }).count + 1
        self.bill_id = "R#{digits}-#{num}"
        self.save
      end
    end
end
