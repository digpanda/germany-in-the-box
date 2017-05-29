require 'will_paginate/array'

class Order
  include MongoidBase
  include HasProductSummaries

  Numeric.include CoreExtensions::Numeric::CurrencyLibrary

  UNPROCESSABLE_TIME = [11,12] # 11am to 12am -> German Hour
  BOUGHT_OR_CANCELLED = [:paid, :custom_checkable, :custom_checking, :shipped, :cancelled]
  BOUGHT_OR_UNVERIFIED = [:payment_unverified, :paid, :custom_checkable, :custom_checking, :shipped]

  field :status,                    type: Symbol, default: :new
  field :desc,                      type: String
  field :border_guru_quote_id,      type: String

  field :logistic_partner, type: Symbol, default: :manual
  field :border_guru_order_id,      type: String
  field :border_guru_shipment_id,   type: String
  field :border_guru_link_tracking, type: String
  field :border_guru_link_payment,  type: String
  field :order_items_count,         type: Fixnum, default: 0
  field :minimum_sending_date,      type: Time
  field :hermes_pickup_email_sent_at, type: Time
  field :bill_id, type: String
  field :paid_at, type: Time
  field :cancelled_at, type: Time

  field :shipping_cost

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

  # def shipping_cost
  #   @shipping_cost ||= begin
  #     order_items.reduce(0) do |acc, order_item|
  #       if order_item.shipping_per_unit
  #         acc + (order_item.shipping_per_unit * order_item.quantity)
  #       end
  #     end
  #   end
  # end

  # the taxes cost appears systematically `recalculated`
  # but it's actually taken from hard written `order_item` taxes cost
  def taxes_cost
    @taxes_cost ||= begin
      order_items.reduce(0) do |acc, order_item|
        acc + (order_item.taxes_per_unit * order_item.quantity)
      end
    end
  end

  def referrer
    coupon&.referrer
  end

  belongs_to :shop, :inverse_of => :orders
  belongs_to :user, :inverse_of => :orders
  belongs_to :cart, :inverse_of => :orders
  belongs_to :coupon, :inverse_of => :orders

  embeds_one :shipping_address, :class_name => 'Address'
  embeds_one :billing_address, :class_name => 'Address'

  has_many :order_items,            :inverse_of => :order,    dependent: :restrict
  has_many :order_payments,         :inverse_of => :order,    dependent: :restrict
  has_many :notes,                  :inverse_of => :order,    dependent: :restrict
  has_one :referrer_provision,    :inverse_of => :order,    dependent: :restrict


  scope :nonempty,    ->  {  where( :order_items_count.gt => 0 ) }
  scope :unpaid,      ->  { self.in(:status => [:new]) }
  scope :bought,      ->  { self.in(:status => [:paid, :custom_checkable, :custom_checking, :shipped]) }
  scope :bought_or_cancelled, -> { self.in( :status => BOUGHT_OR_CANCELLED ) }
  scope :bought_or_unverified,      ->  { self.in( :status => BOUGHT_OR_UNVERIFIED ) } # cancelled isn't included in this

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
  # :custom_checkable -> the order has been handled by the shopkeeper
  # :custom_checking -> the order is being checked by the customs
  # :shipped -> the shopkepper has sent the package
  # NOTE : don't forget to update the tooltips too
  validates :status, presence: true , inclusion: {in: [:new, :paying, :payment_unverified, :payment_failed, :cancelled, :paid, :custom_checkable, :custom_checking, :shipped]}

  summarizes sku_list: :order_items, by: :quantity

  index({user: 1},  {unique: false,   name: :idx_order_user,   sparse: true})

  before_save :create_border_guru_order_id
  after_save :make_bill_id, :update_paid_at, :update_cancelled_at, :refresh_referrer_provision!

  def create_border_guru_order_id
    unless self.border_guru_order_id
      self.border_guru_order_id = SecureRandom.hex(10)
    end
  end

  # refresh order status from payment
  # if the order is still not send / paid, it checks
  # if there's any change from the payment model
  def refresh_status_from!(order_payment)
    unless bought?
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

  def coupon_discount_in_percent
    # we use the total_price_with_taxes because
    # the coupon_discount is calculated with taxes
    coupon_discount / total_price_with_taxes * 100
  end

  # live referrer provision before it's saved in the database
  def current_referrer_provision
    order_items.reduce(0) do |acc, order_item|
      if order_item.referrer_rate > 0.0
        # it's the total price minus the normalized coupon discount
        calculation_price = order_item.total_price * ((100 - coupon_discount_in_percent) / 100)
        acc += calculation_price * order_item.referrer_rate / 100 # goods price
      else
        0
      end
    end
  end

  def refresh_referrer_provision!
    if referrer
      referrer_provision = ReferrerProvision.where(order: self, referrer: referrer).first
      if bought?
        referrer_provision ||= ReferrerProvision.create(order: self, referrer: referrer)
        referrer_provision.provision = current_referrer_provision
        referrer_provision.save
      else #if cancelled? -> we should actually apply deletion in any case if it's not bought
        referrer_provision&.delete
      end
    end
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

  # NOTE : THIS HAS TO BE REMOVED WHEN STAGING CHANGES WILL BE DONE.
  # WE MADE IT FOR A FEW STUCK ORDERS BUT IT'S VERY SPAGHETTI.
  def total_price_with_discount_from_product
    order_items.inject([]) do |sum, order_item|
        sum << (order_item.price_with_coupon_applied * order_item.quantity)
    end.reduce(&:+)
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

  def total_paid(currency=:cny)
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
    order_items.where(package_set: nil).count == 0
  end

  def displayable_total_quantity
    package_set_quantity = {}
    order_items.inject(0) do |sum, order_item|
      if order_item.package_set
        if package_set_quantity["#{order_item.package_set.id}"].nil?
          package_set_quantity["#{order_item.package_set.id}"] = true
          if order_item.package_set.package_skus.count > 0
            sum += order_items.where(package_set_id: order_item.package_set.id).count / order_item.package_set.package_skus.count
          else
            sum += 0
          end
        else
          sum
        end
      else
        sum += order_item.quantity
      end
    end
  end

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
    status == :paid && processable_time?
  end

  def cancellable?
    status != :cancelled && status != :unverified
  end

  def processable_time?
    Time.now.utc.in_time_zone("Berlin").strftime("%k").to_i < UNPROCESSABLE_TIME.first || Time.now.utc.in_time_zone("Berlin").strftime("%k").to_i >= UNPROCESSABLE_TIME.last
  end

  def shippable?
    self.status == :custom_checking && Time.now.utc > minimum_sending_date
  end

  def paid?
    ([:new, :paying].include? self.status) == false
  end

  # we considered as bought any status after paid
  def bought?
    [:paid, :custom_checkable, :custom_checking, :shipped].include?(status) && paid_at
  end

  def new?
    [:new].include?(status)
  end

  def destroyable?
    order_items.count == 0 && order_payments.count == 0
  end

  def reach_todays_limit?(new_price_increase, new_quantity_increase)
    if order_items.size == 0 && new_quantity_increase == 1
      false
    elsif order_items.size == 1 && new_quantity_increase == 0
      false
    else
      (total_price.in_euro.to_yuan.amount + new_price_increase) > Setting.instance.max_total_per_day
    end
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
    order_items.where(package_set: package_set).count / package_set.package_skus.count
  end

  def package_set_total(package_set)
    package_set.end_price * package_set_quantity(package_set)
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
      digits = start_day.strftime("%Y%m%d")
      num = Order.where({:bill_id.ne => nil}).where({:paid_at.gte => start_day}).count + 1
      self.bill_id = "P#{digits}-#{num}"
      self.save
    end
  end

end
