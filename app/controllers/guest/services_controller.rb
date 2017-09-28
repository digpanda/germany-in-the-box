class Guest::ServicesController < ApplicationController
  attr_reader :service, :category, :brand

  before_filter do
    restrict_to :customer
  end

  before_action :set_service
  before_action :freeze_header

  def show
  end

  # we show the list of package by category
  # otherwise we redirect the user to the /categories area
  def index
    @services = Service.active.order_by(position: :asc)
  end

  private

    def set_service
      @service = Service.find(params[:id] || params[:service_id]) if params[:id] || params[:service_id]
    end
end
