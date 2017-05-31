class Api::Guest::OrderItemsController < Api::ApplicationController

  attr_reader :order, :order_item, :product, :sku, :quantity

  before_action :set_product_and_sku, :set_order, only: :create
  before_action :set_order_item, except: :create
  before_action :set_quantity, only: [:create, :update]

  # we add the sku through the order maker and check success
  # if it's a success, we store the order into the cart
  def create
    add_sku = order_maker.sku(sku, quantity).add
    if add_sku.success?
      cart_manager.store(order)
      render json: {success: true, message: I18n.t(:add_product_ok, scope: :edit_order)}
    else
      render json: throw_error(:unable_to_process).merge(error: add_sku.error[:error])
    end
  end

  def update
    @order = order_item.order
    @sku = order_item.sku

    quantity_difference = quantity - order_item.quantity
    original_quantity = order_item.quantity
    original_total = order_item.total_price_with_taxes.in_euro.to_yuan.display

    # NOTE : we base our order maker mechanism on the sku origin
    # and not the order item sku, be aware of that.
    refresh = order_maker.sku(order_item.sku_origin, quantity_difference).add
    unless refresh.success?
      render json: throw_error(:unable_to_process)
                   .merge(error: refresh.error[:error],
                          original_quantity: original_quantity,
                          original_total: original_total)
      return
    end

    # mongoid is a joke
    # - Laurent
    order.reload
  end

  def destroy
    if order_item.destroy && destroy_empty_order!
      @order = order_item.order

      if @order.persisted?
        CouponHandler.new(identity_solver, order.coupon, order).reset if order.coupon
        render 'api/guest/order_items/update'
      else
        render json: {success: true, order_empty: !@order.persisted?}
      end
    else
      render json: throw_error(:unable_to_process).merge(error: order_item.errors.full_messages.join(', '))
    end
  end

  def destroy_empty_order!
    order = order_item.order

    if order.destroyable?
      order.remove_coupon(identity_solver) if order.coupon
      order.reload
      return order.destroy
    end

    true
  end

  private

  def order_maker
    @order_maker ||= OrderMaker.new(identity_solver, order)
  end

  def set_product_and_sku
    @product = Product.find(params[:product_id])
    @sku = product.skus.where(id: params[:sku_id]).first
  end

  def set_order
    @order = cart_manager.order(shop: product.shop, call_api: false)
  end

  def set_order_item
    @order_item = OrderItem.find(params[:id])
  end

  def set_quantity
    @quantity = params[:quantity].to_i
  end

end
