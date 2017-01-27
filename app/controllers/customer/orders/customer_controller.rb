# we control everything linked to the customer of the order
# this is supposed to be the first step the cart
# and before the checkout
class Customer::Orders::CustomerController < ApplicationController

  attr_reader :order, :customer

  authorize_resource :class => false
  before_action :set_order

  # we only check if the customer has all the required datas
  # we go directly to the next step if it's the case
  def show
    @customer = current_user

    if customer.valid_for_checkout?
      redirect_to customer_order_addresses_path(order)
      return
    end
  end

  private

  def set_order
    @order = current_user.orders.find(params[:order_id])
  end

end
