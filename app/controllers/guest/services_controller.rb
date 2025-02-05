class Guest::ServicesController < ApplicationController
  attr_reader :service, :category, :brand

  before_filter do
    restrict_to :customer
  end

  before_action :set_service
  before_action :set_brand, only: [:index]

  def show
    # if the customer wants to send an inquiry
    # we prepare it first
    @inquiry = Inquiry.new
  end

  # we show the list of package by category
  # otherwise we redirect the user to the /categories area
  def index
    @services = Service.active.without_referrer.order_by(position: :asc)
    @referrer_services = Service.active.with_referrer.order_by(position: :asc) if current_user&.referrer?
    # brand querying
    if brand
      @services = @services.with_brand(brand)
      @referrer_services = @referrer_services.with_brand(brand) if current_user&.referrer?
    end

    @brand_filters = Brand.with_services.order_by(position: :asc).used_as_filters
  end

  private

    # NOTE : this was copied from package_sets_controller
    # If in any case we duplicate again, please abstract it elsewhere.
    # for filtering (optional)
    def set_brand
      if params[:brand_id]
        begin
          @brand = Brand.find(params[:brand_id])
        rescue Mongoid::Errors::DocumentNotFound
          # we need to rescue to avoid crashing the application
          # like for the category_id above
        end
      end
    end

    def set_service
      @service = Service.find(params[:id] || params[:service_id]) if params[:id] || params[:service_id]
    end
end
