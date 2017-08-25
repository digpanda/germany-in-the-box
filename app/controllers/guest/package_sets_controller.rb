class Guest::PackageSetsController < ApplicationController
  attr_reader :package_set, :category, :brand

  before_filter do
    restrict_to :customer
  end

  before_action :set_package_set, :set_category, :set_brand

  before_action :breadcrumb_package_set, only: [:show]
  before_action :breadcrumb_package_sets, only: [:index]
  before_action :freeze_header

  def show
  end

  def categories
    @brand_filters = Brand.with_package_sets.order_by(position: :asc).used_as_filters
  end

  # we show the list of package by category
  # otherwise we redirect the user to the /categories area
  def index
    @package_sets = PackageSet.active.order_by(position: :asc)

    # category querying
    if category
      @package_sets = @package_sets.with_category(category)
    end

    # brand querying
    if brand
      @package_sets = @package_sets.with_brand(brand)
    end

    # if there's no brand and category
    # we redirect to the category landing page
    unless valid_filters?
      redirect_to guest_package_sets_categories_path
      return
    end

    @package_sets = @package_sets.all

    # now we manage the brand filters
    # if we are in a specific category
    # we just get the category brands
    if category
      @brand_filters = category.package_set_brands
    else
      @brand_filters = Brand.with_package_sets.order_by(position: :asc).used_as_filters
    end
  end

  # we use the package set and convert it into an order
  def update
    # we first compose the whole order
    package_set.package_skus.each do |package_sku|
      # we also lock each order item we generate
      order_maker.add(package_sku.sku, package_sku.product, package_sku.quantity,
                      price: package_sku.price,
                      taxes: package_sku.taxes_per_unit,
                      shipping: package_set.shipping_cost, # total shipping cost of the order
                      locked: true,
                      package_set: package_sku.package_set)
    end
    # we first empty the cart manager to make it fresh
    # cart_manager.empty! <-- to avoid multiple package order
    cart_manager.store(order)
    redirect_to customer_cart_path
  end

  private

    def valid_filters?
      category || brand || params[:category_slug] == 'all'
    end

    # to be abstracted somewhere else
    def order_maker
      @order_maker ||= OrderMaker.new(order)
    end

    def order
      @order ||= cart_manager.order(shop: package_set.shop)
    end
    # end of abstraction

    def set_package_set
      @package_set = PackageSet.find(params[:id]) unless params[:id].nil?
    end

    # for filtering (optional)
    def set_category
      @category = Category.where(slug: params[:category_slug]).first if params[:category_slug]
    end

    # for filtering (optional)
    # NOTE : we avoid crashing it if not found
    def set_brand
      @brand = Brand.where(id: params[:brand_id]).first if params[:brand_id]
    end
end
