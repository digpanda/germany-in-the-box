require 'csv'
require 'net/ftp'

class Shared::OrdersController < ApplicationController
  attr_reader :order

  authorize_resource class: false
  before_action :set_order
  before_filter :is_admin_or_shop_order

  def show
    I18n.locale = :de # TODO : make a helper for that
    respond_to do |format|
      format.csv do
        render text: 'This functionality has been deactivated temporarily.'
      end
    end
  end

  def bill
    respond_to do |format|
      format.pdf do
        render pdf: "#{bill_file_name}", disposition: disposition,
               margin: { bottom: 30 },
               footer: { html: { template: 'layouts/pdf/footer.pdf.erb' } }
      end
    end
  end

  # NOTE : official_bill is in /guest/ area

  def cancel
    canceller = OrderCanceller.new(order).all!
    if canceller.success?
      flash[:success] = 'Order was cancelled successfully.'
      redirect_to(:back)
    else
      flash[:error] = "#{canceller.error}"
      redirect_to(:back)
    end
  end

  private

    def disposition
      @disposition ||= params[:disposition] || 'attachment' # e.g. inline
    end

    def bill_file_name
      order.bill_id || order.id
    end

    def set_order
      @order = Order.find(params[:id] || params[:order_id])
    end

    def is_admin_or_shop_order
      current_user.decorate.admin? || order.shop.id == current_user.shop.id
    end
end
