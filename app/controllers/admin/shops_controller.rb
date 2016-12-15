class Admin::ShopsController < ApplicationController

  attr_accessor :shop, :shops

  authorize_resource :class => false
  before_action :set_shop, :except => [:index, :emails]
  before_action :breadcrumb_admin_shops
  before_action :breadcrumb_admin_shop, only: [:show]

  layout :custom_sublayout

  def index
    @shops = Shop.order_by(:c_at => :desc).paginate(:page => current_page, :per_page => 10)
  end

  def show
  end

  def update
    if shop.update(shop_params)
      flash[:success] = I18n.t(:update_ok, scope: :edit_shop)
    else
      flash[:error] = shop.errors.full_messages.join(', ')
    end
    redirect_to navigation.back(1)
  end

  def destroy
    if shop.addresses.delete_all && shop.payment_gateways.delete_all && shop.destroy
      flash[:success] = I18n.t(:delete_ok, scope: :edit_shops)
    else
      flash[:error] = shop.errors.full_messages.join(', ')
    end
    redirect_to navigation.back(1)
  end

  def destroy_image
    if ImageDestroyer.new(shop).perform(params[:image_field])
      flash[:success] = I18n.t(:removed_image, scope: :action)
    else
      flash[:error] = I18n.t(:no_removed_image, scope: :action)
    end
    redirect_to navigation.back(1)
  end

  def emails
    shops = Shop.all
    shop_emails = shops.reduce([]) { |acc, shop| acc << shop.mail } # could be in model
    shopkeeper_emails = shops.map { |shop| shop.shopkeeper }.reduce([]) { |acc, user| acc << user.email } # could be in model
    @emails_list = (shop_emails + shopkeeper_emails).uniq
  end

  def approve
    shop.approved = Time.now.utc
    unless @shop.save
      flash[:error] = "Can't approve the shop : #{shop.errors.full_messages.join(', ')}"
    end
    redirect_to navigation.back(1)
  end

  def disapprove
    shop.approved = nil
    unless @shop.save
      flash[:error] = "Can't disapprove the shop : #{shop.errors.full_messages.join(', ')}"
    end
    redirect_to navigation.back(1)
  end

  def force_login
    sign_in(shop.shopkeeper)
    redirect_to root_path
  end

  private

  def shop_params
    params.require(:shop).permit!
  end

  def set_shop
    @shop = Shop.find(params[:id] || params[:shop_id])
  end

end
