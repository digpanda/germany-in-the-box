class ShopApplicationController < ApplicationController

  before_action :authenticate_user!, except: [:index, :new, :update, :create]

  def new
  end

  def create
    @shop_application = ShopApplication.new(shop_application_params)

    if @shop_application.save
      flash[:success] = I18n.t(:shop_application_ok, scope: :shop_application)
    else
      flash[:error] = @shop_application.errors.full_messages.first
    end

    redirect_to root_path
  end

  def index
    render :new
  end

  private

  def shop_application_params
    params.require(:shop_application).permit(:email, :name, :desc, :philosophy, :stories, :founding_year, :register)
  end

end