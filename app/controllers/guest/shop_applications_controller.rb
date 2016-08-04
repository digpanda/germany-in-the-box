require "uri"
require "net/http"

class Guest::ShopApplicationsController < ApplicationController

  attr_reader :shop_application

  def new
    @shop_application = ShopApplication.new
  end

  def create

    @shop_application = ShopApplication.new(shop_application_params)
    return throw_model_error(shop_application, :new) unless shop_application.save

    user = shopkeeper_from_shop_application!(shop_application)
    shop_application.delete and return throw_model_error(user, :new) if user.errors.any? # rollback

    shop = Shop.new(shop_params)
    shop.shopname = shop.name # marketing name
    shop.shopkeeper = user

    unless shop.save
      shop_application.delete
      user.delete
      return throw_model_error(shop, :new)
    end

    flash[:success] = I18n.t(:no_applications, scope: :edit_shop_application)
    redirect_to navigation.back(2) and return

  end

  private

  def shopkeeper_from_shop_application!(shop_application)

    User.create({

      :username => shop_application.email,
      :email => shop_application.email,
      :password => shop_application.code[0, 8],
      :password_confirmation => shop_application.code[0, 8],
      :role => :shopkeeper

    })

  end

  def shop_params
    shop_application_params.except(:email)
  end

  def shop_application_params
    params.require(:shop_application).permit(:email, :name, :shopname, :desc, :philosophy, :stories, :german_essence, :uniqueness, :founding_year, :register, :website, :fname, :lname, :tel, :mobile, :mail, :function)
  end

end