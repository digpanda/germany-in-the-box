class Admin::OrdersController < ApplicationController

  CSV_ENCODE = "UTF-8"

  attr_accessor :order, :orders

  authorize_resource :class => false
  before_action :set_order, :except => [:index]

  layout :custom_sublayout

  def index
    respond_to do |format|
      format.html do
        @orders = Order.nonempty.order_by(:c_at => :desc).paginate(:page => current_page, :per_page => 10)
      end
      format.csv do
        @orders = Order.nonempty.order_by(:c_at => :desc)
        render text: OrdersFormatter.new(orders).to_csv.encode(CSV_ENCODE),
               type: "text/csv; charset=#{CSV_ENCODE}; header=present",
               disposition: 'attachment'
      end
    end
  end

  def show
  end

  def update
    if order.update(order_params)
      flash[:success] = "The order was updated."
    else
      flash[:error] = "The order was not updated (#{order.errors.full_messages.join(', ')})"
    end
    redirect_to navigation.back(1)
  end

  def destroy
    if order.delete
      flash[:success] = "The order was deleted."
    else
      flash[:error] = "The order was not deleted (#{order.errors.full_messages.join(', ')})"
    end
    redirect_to navigation.back(1)
  end

  def reset_border_guru_order
    response = get_shipping_refresh!
    if response.success?
      flash[:success] = "Shipping was attributed."
    else
      flash[:error] = "A problem occurred while communicating with BorderGuru Api (#{response.error.message})"
    end
    redirect_to navigation.back(1)

  end

  private

  def get_shipping_refresh!
    # we cancel the order from BorderGuru ONLY
    # not the order itself
    OrderCanceller.new(order).border_guru_cancel_order!
    # we recreate a new order ID
    order.border_guru_order_id = nil
    order.save
    # now we get the fresh shipping
    BorderGuruApiHandler.new(order).get_shipping!
  end

  def set_order
    @order = Order.find(params[:id] || params[:order_id])
  end

  def order_params
    params.require(:order).permit!
  end

end
