class AddressesController < ApplicationController

  before_action :authenticate_user!

  # THIS AREA IS MESSY AS FUCK. I DISABLED THE PROTECTION TEMPORARILY BECAUSE IT MAKES TOO MUCH TROUBLE.
  load_and_authorize_resource :except => [:show_addresses, :index, :create, :update, :destroy]

  layout :custom_sublayout, only: [:show_addresses]

  def show_addresses

    @address = Address.new

    @user = User.find(params[:id])

    if @user.decorate.shopkeeper?
      @addresses = @user.shop.addresses
    elsif @user.decorate.customer?
      @addresses = @user.addresses
    end
    render "#{@user.role}_addresses" # definitely to refactor
  end

  def index
    if current_user.decorate.customer?
      @addresses = current_user.addresses
      render :index, :status => :ok
    end
  end

  def create
    user = current_user # changed by Laurent to hook fast the system
    # we should refactor all this.

    if user.decorate.customer?
      num_addresses = user.addresses.count

      if num_addresses >= Rails.configuration.max_num_addresses

        flash[:error] = I18n.t(:create_ko, scope: :edit_address)
        redirect_to request.referrer
        return

      else
        ap = address_params
        ap[:primary] = true if num_addresses == 0

        ap[:district] = ChinaCity.get(ap[:district])
        ap[:city] = ChinaCity.get(ap[:city])
        ap[:province] = ChinaCity.get(ap[:province])
        ap[:country] = 'CN'

        address = Address.new(ap)
        address.user = user

        if (flag = address.save)
          if address.primary and num_addresses > 0
            user.addresses.select { |a| a.primary and a != address } .each do |a|
              a.primary = false
              flag &&= a.save
            end
          end
        end
      end
    elsif user.decorate.shopkeeper?

      num_addresses = user.shop.addresses.count
      max_num_addresses = Rails.configuration.max_num_shop_billing_addresses + Rails.configuration.max_num_shop_sender_addresses

      if num_addresses >= max_num_addresses

        flash[:error] = I18n.t(:create_ko, scope: :edit_address)
        redirect_to request.referrer

      else
        ap = address_params
        ap[:country] = 'DE'

        address = Address.new(ap)
        address.shop = user.shop

        flag = address.save
      end

    end

    if flag
      flash[:success] = I18n.t(:create_ok, scope: :edit_address)
      redirect_to request.referrer
    else
      flash[:error] = I18n.t(:create_ko, scope: :edit_address)
      redirect_to request.referrer
    end
  end

  def update
    if current_user.decorate.customer?
      if (address = current_user.addresses.find(params[:id]))
        ap = address_params

        ap[:district] = ChinaCity.get(ap[:district])
        ap[:city] = ChinaCity.get(ap[:city])
        ap[:province] = ChinaCity.get(ap[:province])
        ap[:country] = 'CN'

        if (flag = address.update(ap))
          if address.primary
            current_user.addresses.select { |a| a.primary and a != address } .each do |a|
              a.primary = false
              flag &&= a.save
            end
          end
        end
      end
    elsif current_user.decorate.shopkeeper?
      address = current_user.shop.addresses.find(params[:id])
      ap = address_params
      ap[:country] = 'DE'
      flag = address.update(ap)
    elsif current_user.decorate.admin?
      address = Address.find(params[:id])
      ap = address_params
      flag = address.update(ap)
    end

    if flag
      flash[:success] = I18n.t(:update_ok, scope: :edit_address)
      redirect_to request.referer
    else
      flash[:error] = I18n.t(:update_ko, scope: :edit_address)
      redirect_to request.referer
    end
  end

  def destroy
    if current_user.decorate.customer?
      if (address = current_user.addresses.find(params[:id]))
        flag = address.delete

        if address.primary
          candidate = current_user.addresses.not.where(:id => address.id).first

          if candidate
            candidate.primary = true
            flag &&= candidate.save
          end
        end
      end
    elsif current_user.decorate.shopkeeper?
      address = current_user.shop.addresses.find(params[:id])
      flag = address.delete
    elsif current_user.decorate.admin?
      address = Address.find(params[:id])
      flag = address.delete
    end


    if flag
      flash[:success] = I18n.t(:delete_ok, scope: :edit_address)
      redirect_to request.referer
    else
      flash[:error] = I18n.t(:delete_ko, scope: :edit_address)
      redirect_to request.referer
    end
  end

  private

  def address_params
    if current_user.decorate.customer?
      params.require(:address).permit(:street,
                                      :district,
                                      :city,
                                      :province,
                                      :zip,
                                      :primary,
                                      :mobile,
                                      :tel,
                                      :fname,
                                      :lname,
                                      :pid)
    elsif current_user.decorate.admin? || current_user.decorate.shopkeeper?
      params.require(:address).permit(:number,
                                      :street,
                                      :additional,
                                      :district,
                                      :city,
                                      :province,
                                      :zip,
                                      :type,
                                      :mobile,
                                      :tel,
                                      :fname,
                                      :lname,
                                      :company)
    end
  end

end
