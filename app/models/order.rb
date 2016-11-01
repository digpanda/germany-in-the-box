require 'will_paginate/array'

class Order
  include MongoidBase
  include HasProductSummaries

  Numeric.include CoreExtensions::Numeric::CurrencyLibrary

  UNPROCESSABLE_TIME = [9,10] # 9am to 10am -> German Hour

  field :status,                    type: Symbol, default: :new
  field :desc,                      type: String
  field :border_guru_quote_id,      type: String
  field :shipping_cost,             type: Float, default: 0
  field :tax_and_duty_cost,         type: Float, default: 0
  field :border_guru_shipment_id,   type: String
  field :border_guru_link_tracking, type: String
  field :border_guru_link_payment,  type: String
  field :order_items_count,         type: Fixnum, default: 0
  field :minimum_sending_date,      type: Time
  field :hermes_pickup_email_sent_at, type: Time
  field :bill_id, type: String
  field :paid_at, type: Time
  field :cancelled_at, type: Time

  field :coupon_applied_at, type: Time
  field :coupon_discount, type: Float, default: 0.0

  belongs_to :shop, :inverse_of => :orders
  belongs_to :user, :inverse_of => :orders

  belongs_to :coupon, :inverse_of => :orders

  belongs_to :shipping_address,        :class_name => 'Address'
  belongs_to :billing_address,         :class_name => 'Address'

  has_many :order_items,            :inverse_of => :order,    dependent: :restrict
  has_many :order_payments,         :inverse_of => :order,    dependent: :restrict
  has_many :notes,                  :inverse_of => :order,    dependent: :restrict

  scope :nonempty,    ->  {  where( :order_items_count.gt => 0 ) }
  scope :bought,      ->  { self.in( :status => [:paid, :custom_checkable, :custom_checking, :shipped] ) }
  scope :bought_or_cancelled, -> { self.in( :status => [:paid, :custom_checkable, :custom_checking, :shipped, :cancelled] ) }
  scope :bought_or_unverified,      ->  { self.in( :status => [:payment_unverified, :paid, :custom_checkable, :custom_checking, :shipped] ) } # cancelled isn't included in this

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

  after_save :make_bill_id, :update_paid_at, :update_cancelled_at

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

  # total price of the products in the order (raw price before any alteration)
  # memoization for performance
  def total_price
    @total_price ||= begin
      if self.bought?
        order_items.inject(0) { |sum, order_item| sum += order_item.quantity * order_item.price }
      else
        order_items.inject(0) do |sum, order_item|
          if order_item.product
            sum += order_item.quantity * order_item.sku.price
          end
        end
      end
    end
  end

  def total_discount
    coupon_discount
  end

  def total_discount_percent
    total_price_with_discount / total_price
  end

  # extra costs (shipping and taxes)
  def extra_costs
    shipping_cost + tax_and_duty_cost
  end

  # total price with the coupon discount if any
  def total_price_with_discount
    total_price - coupon_discount
  end

  # total price of the products with the shipping cost
  def total_price_with_extra_costs
    total_price + extra_costs
  end

  # this the price with discount applied and adding up the extra costs afterwards
  def total_price_with_discount_and_extra_costs
    total_price_with_discount + extra_costs
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

  # DON'T EXIST ANYMORE ? - Laurent on 29/06/2016
  def is_success?
    self.status == :success
  end

  def paid?
    ([:new, :paying].include? self.status) == false
  end

  # we considered as bought any status after paid
  def bought?
    [:paid, :custom_checkable, :custom_checking, :shipped].include?(status)
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
      (total_price.in_euro.to_yuan.amount + new_price_increase) > Settings.instance.max_total_per_day
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
      start_day = c_at.beginning_of_day
      digits = start_day.strftime("%Y%m%d")
      num = Order.where({:bill_id.ne => nil}).where({:c_at.gte => start_day}).count + 1
      self.bill_id = "P#{digits}-#{num}"
      self.save
    end
  end

end
