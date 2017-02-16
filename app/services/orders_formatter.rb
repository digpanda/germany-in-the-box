require 'csv'

# generate format for orders model (CSV for admin, ...)
class OrdersFormatter < BaseService

  include Rails.application.routes.url_helpers

  CSV_LINE_CURRENCY = 'EUR'
  MAX_DESCRIPTION_CHARACTERS = 200
  HEADERS = [
    'Order ID',
    'Customer',
    'Billing Address',
    'Status',
    'Description',
    'Clean Description',
    'Products',
    'Products descriptions',
    'Total Quantity',
    'Total Volume',
    'Total products price (EUR)',
    'Total products price (CNY)',
    'Shipping Cost (EUR)',
    'Shipping Cost (CNY)',
    'Tax and Duty Cost (EUR)',
    'Tax and Duty Cost (CNY)',
    'End price (EUR)',
    'End price (CNY)',
    'Coupon code',
    'Coupon discount',
    'Coupon discount (EUR)',
    'Coupon description',
    'Total paid (EUR)',
    'Total paid (CNY)',
    'Total items',
    'Merchant Id',
    'BorderGuru Merchant Id',
    'BorderGuru Quote ID',
    'BorderGuru Shipment ID',
    'BorderGuru Order ID',
    'BorderGuru Link Tracking',
    'BorderGuru Link Payment',
    'Payments IDs',
    'Payments Methods',
    'Transactions Types',
    'Wirecard Transactions IDs',
    'Wirecard Request IDs',
    'Minimum Sending Date',
    'Hermes Pickup Email Sent At',
    'Bill ID',
    'Paid At',
    'Created At',
    'Updated At',
  ]

  attr_reader :orders

  def initialize(orders)
    @orders = orders
  end


  # convert a list of orders (model) into a normalized CSV file
  def to_csv
    CSV.generate do |csv|
      csv << HEADERS
      orders.each do |order|
        csv << csv_line(order)
      end
    end
  end

  private

  def csv_line(order)
    [
      order.id,
      chinese_full_name(order),
      full_address(order),
      order.status,
      order.desc,

      order.decorate.clean_desc,
      order_item_names(order),

      order.decorate.clean_order_items_description,
      order.decorate.total_quantity,
      order.decorate.total_volume,

      order.decorate.total_price.in_euro.amount,
      order.decorate.total_price.in_euro.to_yuan.amount,
      order.decorate.shipping_cost.in_euro.amount,
      order.decorate.shipping_cost.in_euro.to_yuan.amount,
      order.decorate.taxes_cost.in_euro.amount,
      order.decorate.taxes_cost.in_euro.to_yuan.amount,
      order.decorate.end_price.in_euro.amount,
      order.decorate.end_price.in_euro.to_yuan.amount,

      (order.coupon ? order.coupon.code : ''),
      (order.coupon ? order.coupon.decorate.discount_display : ''),
      (order.coupon_discount ? order.coupon_discount : ''),
      (order.coupon ? order.coupon.desc : ''),

      order.total_paid(:eur),
      order.total_paid(:cny),
      order.order_items.count,

      (order.shop ? order.shop.merchant_id : ''),
      (order.shop ? order.shop.bg_merchant_id : ''),

      order.border_guru_quote_id,
      order.border_guru_shipment_id,
      order.border_guru_order_id,
      order.border_guru_link_tracking,
      order.border_guru_link_payment,
      payments_ids(order),

      payment_methods(order),
      transaction_types(order),

      wirecard_transactions_ids(order),
      wirecard_requests_ids(order),

      order.minimum_sending_date,
      order.hermes_pickup_email_sent_at,
      order.bill_id,
      order.paid_at,
      order.c_at,
      order.u_at,
    ]
  end

  def order_item_names(order)
    order.order_items.reduce([]) { |acc, order_item| acc << order_item.product.name }.join(', ')
  end

  def chinese_full_name(order)
    order.billing_address.decorate.chinese_full_name if order.billing_address
  end

  def full_address(order)
    order.billing_address.decorate.full_address if order.billing_address
  end

  def payments_ids(order)
    order.order_payments.reduce([]) { |acc, order_payment| acc << order_payment.id }.join(', ')
  end

  def wirecard_requests_ids(order)
    order.order_payments.reduce([]) { |acc, order_payment| acc << order_payment.request_id }.join(', ')
  end

  def wirecard_transactions_ids(order)
    order.order_payments.reduce([]) { |acc, order_payment| acc << order_payment.transaction_id }.join(', ')
  end

  def payment_methods(order)
    order.order_payments.reduce([]) { |acc, order_payment| acc << order_payment.payment_method }.join(', ')
  end

  def transaction_types(order)
    order.order_payments.reduce([]) { |acc, order_payment| acc << order_payment.transaction_type }.join(', ')
  end

end
