# NOTE : with inherit the addresses system
class Customer::Orders::AddressesController < Customer::AddressesController
  attr_reader :order, :address, :addresses

  authorize_resource class: false
  before_action :set_order
  before_action :set_addresses
  
  layout :default_layout # overwrite the sublayout inherit

  def index
    redirect_to new_customer_order_address_path(order)
  end

  def new
    @address = Address.new
  end

  private

    def set_addresses
      @addresses = current_user.addresses
    end

    def set_order
      @order = current_user.orders.find(params[:order_id])
    end
end
