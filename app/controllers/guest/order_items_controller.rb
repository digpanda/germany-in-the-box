class Guest::OrderItemsController < ApplicationController

  attr_reader :order_item, :order

  before_action :set_order_item, :set_order

  # TODO : this was moved here as `add_product` but needs to be hardly refactored
  # it's very shitty code.
  # it actually adds an order item to the cart itself.
  # maybe we should move it somewhere else

  # TODO: This was moved under api/controllers to make it an AJAX call, this remains here
  # until we know the other call is working properly.
  def create
    product = Product.find(params[:sku][:product_id]).decorate
    sku = product.sku_from_option_ids(params[:sku][:option_ids].split(','))
    quantity = params[:sku][:quantity].to_i

    order = cart_manager.order(shop: product.shop, call_api: false)
    order.shop = product.shop

    if BuyingBreaker.new(order).with_sku?(sku, quantity)
      flash[:error] = I18n.t(:override_maximal_total, scope: :edit_order, total: Setting.instance.max_total_per_day, currency: Setting.instance.platform_currency.symbol)
      redirect_to navigation.back(1)
      return
    end

    if OrderMaker.new(order).add(sku, quantity).success?
      cart_manager.store(order)
      flash[:success] = I18n.t(:add_product_ok, scope: :edit_order)
      redirect_to navigation.back(2, guest_shop_path(product.shop))
      return
    end

    flash[:error] = I18n.t(:add_product_ko, scope: :edit_order)
    redirect_to navigation.back(1)
  end

  def destroy
    if order_item.destroy && destroy_empty_order!
      flash[:success] = I18n.t(:item_removed, scope: :notice)
    else
      flash[:error] = order_item.errors.full_messages.join(', ')
    end
    redirect_to navigation.back(1)
  end

  private

  def destroy_empty_order!
    if order.destroyable?
      order.remove_coupon if order.coupon
      order.reload # because we just deleted the order item
      return order.destroy
    end
    true
  end

  def set_order_item
    @order_item = OrderItem.find(params[:id]) unless params[:id].nil?
  end

  def set_order
    @order = order_item.order if order_item
  end

end
