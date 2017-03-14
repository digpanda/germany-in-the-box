class Admin::Shops::PackageSetsController < ApplicationController

  include DestroyImage

  attr_reader :shop, :package_set, :package_sets

  authorize_resource :class => false
  layout :custom_sublayout

  before_action :set_shop
  before_action :set_package_set, :except => [:index, :new, :create]
  before_action :breadcrumb_admin_shops, :breadcrumb_admin_shop_products

  def index
    @package_sets = shop.package_sets.order_by(position: :asc).paginate(:page => current_page, :per_page => 10)
  end

  def show
    redirect_to edit_admin_shop_package_set_path(shop, package_set)
  end

  def new
    @package_set = PackageSet.new
    build_package_images!
    build_package_skus!
  end

  def create
    @package_set = shop.package_sets.build(package_set_params)
    if package_set.save
      flash[:success] = "Set was created"
      redirect_to admin_shop_package_sets_path(shop)
    else
      flash[:error] = package_set.errors.full_messages.join(', ')

      build_package_skus!
      render :new
    end
  end

  def edit
    build_package_images!
    build_package_skus!
  end

  def update
    if package_set.update(package_set_params)
      clean_up_package_skus!
      flash[:success] = "Set was updated"
      redirect_to navigation.back(1)
    else
      flash[:error] = package_set.errors.full_messages.join(', ')
      build_package_skus!
      render :edit
    end
  end

  def destroy
    if package_set.delete_with_assoc
      flash[:success] = "Set was destroyed"
    else
      flash[:error] = package_set.errors.full_messages.join(', ')
    end
    redirect_to navigation.back(1)
  end

  private

  def params_valid_product_ids
    package_set_params["package_skus_attributes"]&.map do |key, value|
      value["product_id"] unless value["product_id"].empty?
    end&.compact
  end

  def clean_up_package_skus!
    package_set.package_skus.map(&:product_id).map(&:to_s).each do |product_id|
      unless params_valid_product_ids&.include? product_id
        package_set.package_skus.where(product_id: product_id).delete
      end
    end
  end

  def package_set_params
    params.require(:package_set).permit!
  end

  def build_package_images!
    4.times { package_set.images.build }
  end

  def build_package_skus!
    5.times { package_set.package_skus.build }
  end

  def set_shop
    @shop = Shop.find(params[:shop_id] || params[:id])
  end

  def set_package_set
    @package_set = PackageSet.find(params[:package_set_id] || params[:id])
  end

end
