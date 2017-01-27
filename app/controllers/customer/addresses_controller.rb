class Customer::AddressesController < ApplicationController

  attr_reader :address

  authorize_resource :class => false
  layout :custom_sublayout
  before_action :set_address, only: [:show, :edit, :update, :destroy]

  def index
    @addresses = current_user.addresses
  end

  def show
  end

  def new
    @address = Address.new
  end

  def create

    address_params[:country] = 'CN'
    resolve_china_city!

    @address = Address.new(address_params)
    address.user = current_user

    if address.save
      reset_primary_address! if address.primary
      flash[:success] = I18n.t(:create_ok, scope: :edit_address)
      redirect_to navigation.back(2)
      return
    end

    flash[:error] = "#{I18n.t(:create_ko, scope: :edit_address)} (#{address.errors.full_messages.join(', ')})"
    render :new

  end

  def update

    resolve_china_city!
    address_params[:country] = 'CN'

    if address.update(address_params)
      reset_primary_address! if address.primary
      flash[:success] = I18n.t(:update_ok, scope: :edit_address)
      redirect_to navigation.back(2)
      return
    end

    flash[:error] = I18n.t(:update_ko, scope: :edit_address)
    redirect_to navigation.back(1)

  end

  def destroy
    address.delete
    solve_primary_address if address.primary
    redirect_to navigation.back(1)
  end

  private

  def resolve_china_city!
    address_params[:district] = ChinaCity.get(address_params[:district])
    address_params[:city] = ChinaCity.get(address_params[:city])
    address_params[:province] = ChinaCity.get(address_params[:province])
  end

  def solve_primary_address!
    other_address = current_user.addresses.first
    if other_address
      other_address.primary = true
      other_address.save
    end
  end

  def reset_primary_address!
    current_user.addresses.not.where(:id => address.id).each do |other_address|
      other_address.primary = false
      other_address.save
    end
  end

  def set_address
    @address = current_user.addresses.find(params[:id])
  end

  def address_params
    params.require(:address).permit!
  end

end
